- 原型json
  - 主要用于创建一个应用，创建它的相关规则
  - 主要是针对游戏开发者
原型基本样式：
```json
{
    "id":<原型id，必填>,
    "name":<原型名称，必填>,
    "extends":[双亲原型1,双亲原型2,...], //继承，出现同名属性时，优先级由子类、双亲1、双亲2...
    "properties":{ // 属性集合
        "<属性1>":{ // 例如马尼拉，当海盗要花5块钱
            "type":<属性类型>, 
            "default":<属性默认值>,
            "options":[<属性的可选值集合>]
        }
    }
}
组件原型：
```json
{
    "id":<组件原型id，必填>,
    "name":"component",
    "properties":{ // 组件属性集合
        "visible":{ // 是否可见
            "type":"bool"
        },
        "pos_x":{// 组件位置x
            "type":"int"
        },
        "pos_y":{// 组件位置y
            "type":"int"
        },
         "size_w":{// 组件宽度w
            "type":"int"
        },
        "size_h":{// 组件高度h
            "type":"int"
        },
        "movable":{// 是否可移动
            "type":"bool"
        }
    }
}
```

card原型：
```json
{
    "id":<卡牌原型id，必填>,
    "name":"card",
    "extends":["component"]
    "properties":{ // 卡牌属性集合
        "description":{// 卡牌描述
            "type":"String"
        }
        // 照理说应该有卡图属性，但是其实没必要直接写原型这里。应该有一个卡图表
    }
}
```

deck原型：
```json
{
    "id":<牌库原型id，必填>,
    "name":"deck",
    "extends":["component"]
    "properties":{ // 牌库属性集合
        "count":{// 卡牌数目
            "type":"int"
        },
        "infinite":{// 是否是无限牌库。如果是的话，那卡就可能出现同一种卡出现n张（例如小动物自走棋
            "type":"bool"
        },
        "cards":{// 牌库。如果是无限牌库考虑卡的原型，不是无限牌库就是卡的id
            "type":"String[]"
        }
    }
}
```


***

- 实例json
  - 用于游戏中表示具体的对象
```json
{
    "id":<id，必填>,
    "protype":<原型>, //标明是哪个原型的...
    "properties":{ // 属性集合
        "<属性1>":<属性1数值>,
        "<属性2>":<属性2数值>,
        ...
    }
}
```