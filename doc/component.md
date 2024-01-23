# 组件格式

> version `0.1.0`

## 概述

1. 组件的状态使用JSON进行表达
2. 组件的状态与具体的显示方式、交互方式分离，但是给定组件的状态，就能确定显示方式和交互方式
3. 组件的状态整体可分为内置状态（基本状态）和扩展状态（用户定义状态）
4. 通过扩展状态可以对组件进行自定义，但是无论如何扩展，所有组件最终都基于内置的几种基本组件
5. 内置组件隐含了几种内置的交互方式

> 用户脚本通过操作扩展状态实现对组件的扩展，详见用户脚本接口文档

基本组件主要有以下3种：

1. Card：卡牌
2. Deck：牌库
3. Dice：骰子

## 约定

1. `"xxx"`, `"yyy"`, `"zzz"` imply some UTF-8 String
2. `N`, `M`, `P`, `Q`, `X`, `Y`, `Z` imply some Integer
3. `{x}` implies some object
4. `[[ ]]` implies the field is nullable
5. `null` field is equavelant to the absence
6. `|` means or
7. `n.nn`, `m.mm` etc. imply some float number

## Card

```
{
    "type": "Card",
    "id_": P,
    "pos": {Pos},
    "size": {Size},
    "texture": {Texture},
    "visible": true | false,
    "name": [["xxx"]],
    "description": [["xxx"]],
    "other": [[{x}]]
}
```

内置交互方式

1. 点击
2. 双击/选中
3. 拖动/移动
4. 新增
5. 删除
6. 翻面

## Deck

```
{
    "type": "Deck",
    "id_": P,
    "pos": {Pos},
    "size": {Size},
    "texture": {Texture},
    "visible": true | false,
    "name": [["xxx"]],
    "description": [["xxx"]],
    "stack": [{Card}...],
    "other": [[{x}]]
}
```

内置交互方式

1. 点击
2. 双击/选中
3. 新增
4. 删除
5. 抽牌
6. 塞牌
7. 洗牌

## Dice

TODO

## 组件的一些有结构的属性

使用Python数据类进行表达

### Pos

```python
@dataclass
class CardsimPos:
    x: int
    y: int
    z: float
```

### Size

```python
@dataclass
class CardsimSize:
    w: int
    h: int
```

### Pos2f

```python
@dataclass
class CardsimPos2f:
    x: float # between 0 and 1
    y: float # between 0 and 1
```

### Text

```python
@dataclass
class Texture:
    file: Path
    offset: CardsimPos2f
    size: CardsimPos2f
```
