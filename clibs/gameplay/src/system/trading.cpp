#include <system/trading.h>
#include <core/world.h>
#include <lua.hpp>
#include "roadnet_world.h"

constexpr uint8_t BLUE_PRIORITY = 0;
constexpr uint8_t RED_PRIORITY = 0;
constexpr uint8_t GREEN_PRIORITY = 1;

static void trading_match(world& w, uint16_t item, trading_queue& q, uint8_t sell_priority, uint8_t buy_priority) {
    auto& s = q.sell[sell_priority];
    auto& b = q.buy[buy_priority];
    while (!s.empty() && !b.empty()) {
        w.tradings.orders.push({
            item,
            s.front(),
            b.front()
        });
        b.pop();
        s.pop();
    }
}

static void trading_match(world& w, uint16_t item, trading_queue& q) {
    trading_match(w, item, q, 0, 0);
    trading_match(w, item, q, 0, 1);
    trading_match(w, item, q, 1, 0);
}

static void trading_sell(world& w, trading_who who, uint8_t priority, container_slot& s) {
    if (s.amount <= s.lock_item) {
        return;
    }
    uint16_t item = s.item;
    uint16_t amount = s.amount - s.lock_item;
    s.lock_item = s.amount;
    auto& n = w.tradings.queues[item];
    for (uint16_t i = 0; i < amount; ++i) {
        n.sell[priority].push(who);
    }
}

static void trading_buy(world& w, trading_who who, uint8_t priority, container_slot& s) {
    if (s.amount + s.lock_space >= s.limit) {
        return;
    }
    uint16_t item = s.item;
    uint16_t amount = s.limit - s.amount - s.lock_space;
    s.lock_space = s.limit - s.amount;
    auto& n = w.tradings.queues[item];
    for (uint16_t i = 0; i < amount; ++i) {
        n.buy[priority].push(who);
    }
}

void trading_flush(world& w, trading_who who, container_slot& s) {
    if (s.item == 0) {
        return;
    }
    switch (s.type) {
    case container_slot::type::red:
        trading_sell(w, who, RED_PRIORITY, s);
        break;
    case container_slot::type::blue:
        trading_buy(w, who, BLUE_PRIORITY, s);
        break;
    case container_slot::type::green:
        trading_sell(w, who, GREEN_PRIORITY, s);
        trading_buy(w, who, GREEN_PRIORITY, s);
        break;
    }
}

static void queue_remove(queue<trading_who>& queue, trading_who who) {
    auto removed = std::remove_if(queue.begin(), queue.end(), [](auto who){
        return true;
    });
    queue.erase_end(removed);
}

void trading_rollback(world& w, trading_who who, container_slot& s) {
    if (s.item == 0) {
        return;
    }
    auto& n = w.tradings.queues[s.item];
    if (s.lock_item > 0) {
        s.lock_item = 0;
        switch (s.type) {
        case container_slot::type::red:
            queue_remove(n.sell[RED_PRIORITY], who);
            break;
        case container_slot::type::green:
            queue_remove(n.sell[GREEN_PRIORITY], who);
            break;
        }
    }
    if (s.lock_space > 0) {
        s.lock_space = 0;
        switch (s.type) {
        case container_slot::type::blue:
            queue_remove(n.buy[BLUE_PRIORITY], who);
            break;
        case container_slot::type::green:
            queue_remove(n.buy[GREEN_PRIORITY], who);
            break;
        }
    }
}

template <>
uint8_t kdtree_getdata<uint8_t, trading_kdtree::pointcolud>(trading_kdtree::pointcolud const& dataset, uint16_t i, uint8_t dim) {
    if (dim == 0) {
        return dataset[i].x;
    }
    return dataset[i].y;
}

template <bool Check, typename ElementType = uint8_t, typename Dataset = trading_kdtree::pointcolud, typename AccessorType = uint16_t>
class nearest_result {
public:
    nearest_result(roadnet::world& w)
        : w(w)
        , indices()
        , dists((std::numeric_limits<ElementType>::max)())
    {}
    bool hasLorry(const Dataset& dataset, AccessorType index) {
        return w.Endpoint(dataset[index].id).popMap.size() > 0;
    }
    bool addPoint(const Dataset& dataset, ElementType dist, AccessorType index) {
        if ((dists > dist) || ((dist == dists) && (indices > index))) {
            if (!Check || hasLorry(dataset, index)) {
                dists   = dist;
                indices = index;
            }
        }
        return true;
    }
    ElementType accumDist(ElementType a, ElementType b) const {
        return abs(a - b);
    }
    ElementType worstDist() const { return dists; }
    explicit operator bool() const {
        return dists != (std::numeric_limits<ElementType>::max)();
    }
    AccessorType value() const {
        return indices;
    }
private:
    roadnet::world& w;
    AccessorType indices;
    ElementType  dists;
};

static roadnet::world&
getroadnetworld(lua_State* L) {
    lua_getfield(L, LUA_REGISTRYINDEX, "ROADNET_WORLD");
    auto& rw = *(roadnet::world*)lua_touserdata(L, -1);
    lua_pop(L, 1);
    return rw;
}

static roadnet::loction getxy(roadnet::world& w, roadnet::endpointid id) {
    auto& ep = w.Endpoint(id);
    return ep.loc;
}

static void GoHome(world& w, roadnet::world& rw, roadnet::lorryid lorryId, roadnet::endpointid current) {
    auto& kdtree = w.tradings.station_kdtree;
    nearest_result<false> result(rw);
    auto loc = getxy(rw, current);
    if (!kdtree.tree.nearest(result, {loc.x, loc.y})) {
        assert(false);
    }
    rw.pushLorry(lorryId, current, kdtree.dataset[result.value()].id);
}

static bool HasTask(world& w) {
    return !w.tradings.orders.empty();
}

static void DoTask(world& w, roadnet::world& rw, roadnet::lorryid lorryId, roadnet::endpointid current) {
    assert(!w.tradings.orders.empty());
    auto& order = w.tradings.orders.front();
    roadnet::endpointid s{current};
    roadnet::endpointid e{order.sell.endpoint};
    rw.pushLorry(lorryId, s, e);
    auto& l = rw.Lorry(lorryId);
    l.gameplay = {
        order.item,
        {order.sell.endpoint, {order.sell.index.page, order.sell.index.slot}},
        {order.buy.endpoint, {order.buy.index.page, order.buy.index.slot}},
    };
    w.tradings.orders.pop();
}

static int
lbuild(lua_State *L) {
    auto& w = *(world*)lua_touserdata(L, 1);
    auto& rw = getroadnetworld(L);
    auto& kdtree = w.tradings.station_kdtree;
    kdtree.dataset.clear();
    for (auto& v : w.select<ecs::station>(L)) {
        auto& s = v.get<ecs::station>();
        if (s.endpoint != 0xffff) {
            assert(s.endpoint >= 0);
            auto loc = getxy(rw, s.endpoint);
            kdtree.dataset.emplace_back(loc.x, loc.y, s.endpoint);
        }
    }
    kdtree.tree.build();
    return 0;
}

static int
lupdate(lua_State *L) {
    auto& w = *(world*)lua_touserdata(L, 1);
    auto& rw = getroadnetworld(L);
    auto& kdtree = w.tradings.station_kdtree;
    for (auto& [item, q] : w.tradings.queues) {
        trading_match(w, item, q);
    }
    while (!w.tradings.orders.empty()) {
        auto& order = w.tradings.orders.front();
        nearest_result<true> result(rw);
        auto loc = getxy(rw, order.sell.endpoint);
        if (!kdtree.tree.nearest(result, {loc.x, loc.y})) {
            break;
        }
        roadnet::endpointid s{kdtree.dataset[result.value()].id};
        auto lorryId = rw.popLorry(s);
        DoTask(w, rw, lorryId, s);
    }
    for (auto& v : w.select<ecs::chest>(L)) {
        auto& c = v.get<ecs::chest>();
        for (auto lorryId = rw.popLorry(c.endpoint); !!lorryId; lorryId = rw.popLorry(c.endpoint)) {
            auto& l = rw.Lorry(lorryId);
            if (l.gameplay.sell.endpoint == 0xffff) {
                assert(c.endpoint == l.gameplay.buy.endpoint);
                auto& chest = chest::query(c);
                auto& index = l.gameplay.buy.index;
                chest::place_force(w, {index.page, index.slot}, l.gameplay.item, 1);
                if (HasTask(w)) {
                    DoTask(w, rw, lorryId, c.endpoint);
                }
                else {
                    GoHome(w, rw, lorryId, c.endpoint);
                }
            }
            else {
                assert(c.endpoint == l.gameplay.sell.endpoint);
                auto& chest = chest::query(c);
                auto& index = l.gameplay.sell.index;
                chest::pickup_force(w, {index.page, index.slot}, l.gameplay.item, 1);
                rw.pushLorry(lorryId, c.endpoint, l.gameplay.buy.endpoint);
                l.gameplay.sell.endpoint = 0xffff;
            }
        }
    }
    return 0;
}

extern "C" int
luaopen_vaststars_trading_system(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "build", lbuild },
		{ "update", lupdate },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
