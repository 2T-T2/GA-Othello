range = (number, number2)->
    if number2 is undefined
        return [0...number]
    else
        return [number...number2]

log = (val) ->
    console.log(val)

sleep = (ms) ->
    start = new Date().getTime()
    continue while new Date().getTime() - start < ms

boardlog = (val) ->
    str = ""
    for i in range(val.length)
        for j in range(val[0].length)
            if val[i][j] is -1
                str = str + val[i][j] + " "
            else
                str = str + " " + val[i][j] + " "
        str = str + "\n"

randomInt = (num, num2) ->
    if num2 is undefined
        return Math.floor(Math.random() * Math.floor(num))
    else 
        return Math.floor( (num2 - num + 1) * Math.random() + num )

randomArr = (num) ->
    arr = []
    for i in range(num)
        arr.push(Math.random())
    return arr

randomChoiceArr = (arr) ->
    index = randomInt(arr.length)
    return arr[index]

KURO  = -1
SIRO  = 1
BLANK = 0

MaxGeneration = 30
MaxPopulation = 30
MatchNum      = 30

class Main
    constructor: (args) ->
        geneticAlgorithm = new GeneticAlgorithm(KURO)
        gameEnd = false
        
        KURO_Cnt = 0
        SIRO_Cnt = 0
        Drow     = 0
        Win_Cnt  = 0

        for generationCnt in range(MaxGeneration) #世代数ループ
            for number in range(MaxPopulation) #１世代の人数ループ
                for match in range(MatchNum)
                    othello = new Othello()
                    gameEnd = false
                    for i in range(40) #１試合ループ
                        KURO_PlacebleList = othello.getPlacebleList(KURO)
                        if KURO_PlacebleList.length isnt 0
                            othello.reverse(geneticAlgorithm.Act(KURO_PlacebleList, number), KURO)
                            gameEnd = false
                        else
                            if !gameEnd
                                gameEnd = true
                            else
                                break

                        SIRO_PlacebleList = othello.getPlacebleList(SIRO)
                        if SIRO_PlacebleList.length isnt 0
                            othello.reverse(@randomChoice(SIRO_PlacebleList), SIRO)
                            gameEnd = false
                        else
                            if !gameEnd
                                gameEnd = true
                            else
                                break
                    
                    if othello.judge() is geneticAlgorithm.me
                        Win_Cnt++

                geneticAlgorithm.rating(Win_Cnt, number)
                Win_Cnt = 0
                if othello.judge() is KURO
                    KURO_Cnt++
                else if othello.judge() is SIRO
                    SIRO_Cnt++
                else 
                    Drow++
            
            log({"SIRO" : SIRO_Cnt, "KURO" : KURO_Cnt, "Drow" : Drow})
            SIRO_Cnt = 0
            KURO_Cnt = 0
            Drow     = 0
            geneticAlgorithm.makeNextGeneration(generationCnt)

        log geneticAlgorithm.Strongest()
    
    randomChoice : (placeblelist) ->
        index = randomInt(placeblelist.length)
        return placeblelist[index]

class Othello
    board: []
    size: {}
    constructor: ->
        @board = [
            [0, 0, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, -1, 1, 0, 0, 0]
            [0, 0, 0, 1, -1, 0, 0, 0]
            [0, 0, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, 0, 0, 0, 0, 0]
        ]
        @size = {
            "height" : 8
            "width"  : 8
        }

    getPlacebleList: (player)->
        list = []
        for x in range(@size["height"])
            for y in range(@size["width"])
                for dx in range(-1, 2)
                    for dy in range(-1, 2)
                        if dx is 0 and dy is 0
                            continue
                        if @board[y][x] is BLANK
                            cnt = @cntStones(x, y, dx, dy, player)
                            if cnt isnt 0
                                list.push({"x" : x, "y" : y})
        return list

    cntStones : (x, y, dx, dy, player)-> 
        cnt = 1
        if y + cnt * dy < 0 or x + cnt * dx < 0 or y + cnt * dy >= @size["height"] or x + cnt * dx >= @size["width"]
            return 0;
        while @board[y + cnt * dy][x + cnt * dx] is -player
            if y + (cnt+1) * dy < 0 or x + (cnt+1) * dx < 0 or y + (cnt+1) * dy >= @size["height"] or x + (cnt+1) * dx >= @size["width"]
                return 0
            cnt++
        if @board[y + cnt * dy][x + cnt * dx] is player
            return cnt - 1

        return 0

    reverse: (putPoint, player) ->
        x = putPoint["x"]
        y = putPoint["y"]

        cnt = 1;
        for dx in range(-1, 2)
            for dy in range(-1, 2)
                if dx is 0 and dy is 0
                    continue
                cnt = @cntStones(x, y, dx, dy, player)
                for p in range(cnt+1)
                    @board[y + p * dy][x + p * dx] = player
    
    judge : () ->
        KURO_Cnt  = 0
        SIRO_Cnt  = 0
        BLANK_Cnt = 0
        for row in @board
            for point in row
                if point is KURO
                    KURO_Cnt++
                else if point is SIRO
                    SIRO_Cnt++
                else 
                    BLANK_Cnt++
        if KURO_Cnt > SIRO_Cnt
            return KURO
        else if KURO_Cnt < SIRO_Cnt
            return SIRO
        else
            return BLANK

class GeneticAlgorithm
    me                : 0
    CurrentGeneration : []
    NextGeneration    : []
    MutaionPer        : 0.01
    CrossPer          : 0.9
    UniformCrossPer   : 0.15
    WinnerSelectionPer: 0.8
    RewardList        : []
    StrongestWinCnt   : 0
    StrongestGane     : []
    constructor : (myColor) ->
        @me = myColor
        for i in range(MaxPopulation)
            @CurrentGeneration.push(randomArr(64))

    Act : (placeblelist, number) ->
        indexList = []
        valList   = []
        for p in placeblelist
            indexList.push(p["x"] * 8 + p["y"])
            valList.push(@CurrentGeneration[number][p["x"] * 8 + p["y"]])
        
        val = Math.max(...valList)
        index = @CurrentGeneration[number].indexOf(val)

        if index is -1
            log(@CurrentGeneration[number][0].length)

        return {"x" : Math.floor(index / 8), "y" : index % 8}

    rating : (winnum, number) -> 
        @RewardList.push({
            "WinCnt" : winnum
            "gane"   : @CurrentGeneration[number]
        })

        if @StrongestWinCnt <= winnum
            @StrongestWinCnt = winnum
            @StrongestGane   = @CurrentGeneration[number]
    
    makeNextGeneration : (geneCnt) ->
        for i in range(MaxPopulation)
            parent = @select()
            if parent.length is 2
                @NextGeneration.push(@cross(parent))
            else
                if Math.random() > @MutaionPer
                    @NextGeneration.push(@copy(parent))
                else 
                    @NextGeneration.push(@mutaion(parent))

        @CurrentGeneration = @NextGeneration
        @NextGeneration    = []
        @RewardList        = []

    mutaion : (parent) ->
        point1 = randomInt(parent[0].length)
        point2 = randomInt(parent[0].length)
        point3 = randomInt(parent[0].length)
        
        val = parent[0]
        val[point1] = Math.random()
        val[point2] = Math.random()
        val[point3] = Math.random()
        return val

    copy : (parent) ->
        return parent[0]

    cross : (parent) ->
        Child = []
        if @UniformCrossPer < Math.random()
            point1 = randomInt(parent[0].length)
            point2 = randomInt(parent[0].length)

            if point1 > point2
                tmp    = point1
                point1 = point2
                point2 = tmp

            arr1 = parent[0].slice(0, point1)
            arr2 = parent[1].slice(point1, point2)
            arr3 = parent[0].slice(point2)

            Child = Child.concat(arr1)
            Child = Child.concat(arr2)
            Child = Child.concat(arr3)
        else 
            for i in range(parent[0].length)
                if 0.5 > Math.random()
                    Child.push(parent[0][i])
                else
                    Child.push(parent[1][i])

        return Child
        
    select : () ->
        parent         = []
        winnerData     = []
        notwinnnerData = []

        for reward in @RewardList
            if reward["WinCnt"] >= MatchNum * 3 / 4
                winnerData.push(reward["gane"])
            else
                notwinnnerData.push(reward["gane"])

        if Math.random() < @WinnerSelectionPer
            parent.push(randomChoiceArr(winnerData))
        else 
            parent.push(randomChoiceArr(notwinnnerData))

        if Math.random() < @CrossPer
            if Math.random() < @WinnerSelectionPer
                parent.push(randomChoiceArr(winnerData))
            else 
                parent.push(randomChoiceArr(notwinnnerData))

        return parent
    
    Strongest : () ->
        return {"win" : @StrongestWinCnt, "gane" : @StrongestGane}

main = new Main()
