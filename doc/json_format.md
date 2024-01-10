## 数据模型json
  - 主要用于创建一个应用，创建它的相关规则
  - 主要是针对游戏开发者
  - 这边是定义一个普遍的数据模型的样式（其实这个已经接近类了，但是可以快速的迭代）  
数据模型基本样式：
```json
{
    "id":<数据模型id，必填>,
    "name":<数据模型名称，必填>,
    "extends":[双亲model1,双亲model2,...], //继承，出现同名属性时，优先级由子类、双亲1、双亲2...
    "properties":{ // 属性集合
        "<属性1>":{ // 例如马尼拉，当海盗要花5块钱
            "type":<属性类型>, // 属性只考虑int/long, bool, float/double, string 这些基本类型和list, dict这两个组合类型（一句话就是json自带的）。这个也可以不填
            "default":<属性默认值>, 
            "options":[<属性的可选值集合。例如角色只有"alive"和"dead"两种状态时，就可以启用这个参数>]
        }
    }
}
```
组件model：
```json
{
    "id":<组件数据模型id，必填>,
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
        "pos_z":{// 组件位置z，可能用于表示组件高度
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

card model：
```json
{
    "id":<卡牌数据模型id，必填>,
    "name":"card",
    "extends":["component"],
    "properties":{ // 卡牌属性集合
        "description":{// 卡牌描述
            "type":"String"
        }
        // 照理说应该有卡图属性，但是其实没必要直接写数据模型这里。应该有一个卡图表
    }
}
```

deck model：
- 注意，除非是无限牌库类，不然卡就是按照顺序放在cards里面的。然后实例化的时候需要shuffle。
```json
{
    "id":<牌库原型id，必填>,
    "name":"deck",
    "extends":["component"],
    "properties":{ // 牌库属性集合
        "count":{// 卡牌数目
            "type":"int"
        },
        "infinite":{// 是否是无限牌库。如果是的话，那卡就可能出现同一种卡出现n张（例如小动物自走棋。
                    // 然后事实上比如dice也可以用无限牌库法实现www
            "type":"bool"
        },
        "random":{// 是否随机（默认是随机。
            "type":"bool",
            "default":true
        },
        "cards":{// 牌库。如果是无限牌库考虑卡的数据模型id，不是无限牌库就是卡的id
            "type":"String[]"
        },
        "top_card":{// 牌堆顶部的牌
            "type":"String"
        }
    }
}
```


***

## 实例json
  - 用于应用中表示具体的对象
  - 对于数据模型中的属性进行填空
  - 如果都有默认值，可以直接把一个数据模型转成一个实例（不过这个和系统没关系）
```json
{
    "id":<id，必填>,
    "model":<数据模型>, //标明是哪个数据模型的...
    "extends":[], //继承其他的实例，可以少填一些值
    "properties":{ // 属性集合
        "<属性1>":<属性1数值>,
        "<属性2>":<属性2数值>,
        ...
    }
}
```

***
## 系统层面的json
系统看到的样式
- 存储数据模型的json
```json
- protype json
{
    "card":[<card model列表>],
    "deck":[<deck model列表>]
}
```

- 存储具体对象的json
```json
- object json
{
    "card":[<card对象表>],
    "deck":[<deck对象表>]
}
```

系统如果只考虑最基础的`card`或`deck`形式，其实可以把数据模型和对象都存数据库（这只是一种存储方式，也可以存json）：
- 以下为`card`对象表存入数据库的示例   

| id     | model     |  visible | pos_x |  ... |  
| ------ | ---------   | ------- | ----- |  ---|  
| 1    | poke      | true     | 0   |  ... |  
| xxx    | xxx       | xxx     | xxx   |  ... |  

- 以下为json格式存储的示例
```json
- 对象示例
{
    "card":[{
    "id":1,
    "model":"poke_card",
    "properties":{ // 组件属性集合
        "visible":true,
        "pos_x":10,
        ...
    },...
}],
    "deck":[
        {
            "id":"Ys3",
            "model":""
        }
    ]
}
```
 

