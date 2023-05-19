local entities = { {
    dir = "N",
    items = { { "铁矿石", 5 }, { "碎石", 2 }, { "铁板", 1 } },
    prototype_name = "指挥中心",
    recipe = "车辆装配",
    x = 126,
    y = 120
  }, {
    dir = "N",
    items = { { "水电站I", 2 }, { "铁制电线杆", 10 }, { "收货车站", 2 }, { "送货车站", 2 }, { "熔炼炉I", 2 }, { "无人机仓库", 5 } },
    prototype_name = "机身残骸",
    x = 107,
    y = 134
  }, {
    dir = "S",
    items = { { "无人机仓库", 4 }, { "采矿机I", 2 }, { "科研中心I", 1 }, { "组装机I", 4 } },
    prototype_name = "机尾残骸",
    x = 110,
    y = 120
  }, {
    dir = "S",
    items = { { "风力发电机I", 1 }, { "锅炉I", 4 }, { "蓄电池I", 10 }, { "运输车框架", 100 }, { "太阳能板I", 6 }, { "蒸汽发电机I", 8 } },
    prototype_name = "机翼残骸",
    x = 133,
    y = 122
  }, {
    dir = "W",
    items = { { "化工厂I", 3 }, { "空气过滤器I", 4 }, { "地下水挖掘机", 4 }, { "电解厂I", 1 } },
    prototype_name = "机头残骸",
    x = 125,
    y = 108
  } }
local road = {}

return {
    name = "纯净模式",
    entities = entities,
    road = road,
}
    