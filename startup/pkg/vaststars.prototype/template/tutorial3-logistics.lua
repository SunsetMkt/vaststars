local entities = { {
    dir = "N",
    items = { { "停车站", 1 },{ "物流站", 3},{"铁制电线杆",15},{"砖石公路-X型",50},},
    prototype_name = "机身残骸",
    x = 109,
    y = 138
  }, {
    dir = "N",
    items = {{ "仓库I", 4 },{ "蓄电池I", 4 },{ "运输车辆I", 10 }, { "轻型太阳能板", 2 }},
    prototype_name = "机头残骸",
    x = 140,
    y = 136
  }, {
    dir = "E",
    items = { { "地下水挖掘机I", 1},{ "锅炉I", 1},{ "蒸汽发电机I", 1}, },
    prototype_name = "机尾残骸",
    x = 129,
    y = 114
  },{
    dir = "N",
    items = {{"碎石", 0},{"碎石", 0},{"铁矿石", 0},{"铁矿石", 0},},
    prototype_name = "仓库I",
    x = 111,
    y = 133
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 109,
    y = 131
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 109,
    y = 135
  },{
    dir = "N",
    items = {},
    prototype_name = "轻型风力发电机",
    x = 110,
    y = 130
  },{
    dir = "N",
    recipe = "铁矿石挖掘",
    prototype_name = "轻型采矿机",
    x = 105,
    y = 136
  },{
    dir = "N",
    recipe = "碎石挖掘",
    prototype_name = "轻型采矿机",
    x = 115,
    y = 127
  },{
    dir = "N",
    items = {},
    prototype_name = "组装机I",
    x = 150,
    y = 129
  },{
    dir = "N",
    items = {},
    prototype_name = "熔炼炉I",
    x = 154,
    y = 129
  },{
    dir = "N",
    items = {},
    prototype_name = "组装机I",
    x = 158,
    y = 129
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 113,
    y = 135
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 113,
    y = 131
  },  {
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 153,
    y = 133
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 154,
    y = 133
  },{
    dir = "N",
    items = {},
    prototype_name = "仓库I",
    x = 155,
    y = 133
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 156,
    y = 133
  },{
    dir = "N",
    items = {},
    prototype_name = "无人机平台I",
    x = 157,
    y = 133
  },{
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 117,
    y = 131
  },{
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 125,
    y = 131
  },{
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 133,
    y = 131
  },{
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 141,
    y = 131
  },{
    dir = "N",
    prototype_name = "铁制电线杆",
    x = 149,
    y = 131
  },{
    dir = "N",
    prototype_name = "指挥中心",
    amount = 0,
    x = 152,
    y = 114
  }, }
  local road = { {
    dir = "E",
    prototype_name = "砖石公路-U型",
    x = 114,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 116,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 118,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 120,
    y = 134
  }, {
    dir = "W",
    prototype_name = "砖石公路-U型",
    x = 122,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-U型",
    x = 130,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 132,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 134,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 136,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-U型",
    x = 144,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 148,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 150,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 152,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 154,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 156,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 158,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 160,
    y = 134
  }, {
    dir = "W",
    prototype_name = "砖石公路-L型",
    x = 162,
    y = 134
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 162,
    y = 132
  }, {
    dir = "S",
    prototype_name = "砖石公路-U型",
    x = 162,
    y = 130
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 160,
    y = 120
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 158,
    y = 120
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 156,
    y = 120
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 154,
    y = 120
  }, {
    dir = "S",
    prototype_name = "砖石公路-L型",
    x = 162,
    y = 120
  }, {
    dir = "N",
    prototype_name = "砖石公路-U型",
    x = 162,
    y = 122
  }, {
    dir = "W",
    prototype_name = "砖石公路-U型",
    x = 138,
    y = 134
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 152,
    y = 120
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 150,
    y = 120
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 126
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 128
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 130
  }, {
    dir = "S",
    prototype_name = "砖石公路-T型",
    x = 146,
    y = 134
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 132
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 124
  }, {
    dir = "E",
    prototype_name = "砖石公路-I型",
    x = 148,
    y = 120
  }, {
    dir = "N",
    prototype_name = "砖石公路-I型",
    x = 146,
    y = 122
  }, {
    dir = "E",
    prototype_name = "砖石公路-L型",
    x = 146,
    y = 120
  } }

local mineral = {
  ["115,127"] = "碎石",
  ["105,127"] = "碎石",
  ["105,136"] = "铁矿石",
  ["115,136"] = "铁矿石",
  ["156,100"] = "铝矿石",
}

return {
    name = "教学:物流搭建",
    entities = entities,
    road = road,
    mineral = mineral,
    order = 7,
    guide = "guide.guide3",
    show = true,
    mode = "adventure",
    start_tech = "物流教学",
}