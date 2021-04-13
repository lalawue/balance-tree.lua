--
-- Copyright (c) 2021 lalawue
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local tree = require("avl").new(function(a, b)
    return a - b
end)

function test_rebalance(tree)
    print("\n0) test insert:")
    tree:insert(10, 100)
    travel_tree(tree, "insert 10: ")

    print("\n1) test LL:")
    tree:insert(8, 80)
    travel_tree(tree, "insert 8: ")
    tree:insert(6, 60)
    travel_tree(tree, "insert 6: ")

    print("\n2) test RR:")
    tree:insert(13, 130)
    travel_tree(tree, "insert 13: ")
    tree:insert(15, 150)
    travel_tree(tree, "insert 15: ")
        
    print("\n3) test LR:")
    tree:insert(4, 40)
    travel_tree(tree, "insert 4: ")
    tree:insert(5, 50)
    travel_tree(tree, "insert 5: ")
        
    print("\n4) test RL:")
    tree:insert(17, 170)
    travel_tree(tree, "insert 17: ")
    tree:insert(16, 160)
    travel_tree(tree, "insert 16: ")

    print("\n5) count: " .. tree:count())
end
    
function test_find_delete_replace(tree)
    print("\n5) find 15: " .. tree:find(15))
    print("   find 19: " .. (tree:find(19) or "nil"))

    print("\n6) delete 13, first, last:")
    tree:remove(13)
    tree:remove(tree:first())
    tree:remove(tree:last())
    travel_tree(tree, "   ")
    print("   count: " .. tree:count())
        
    print("\n7) replace 15 value -> 1500:")
    tree:insert(15, 1500, true)
    print("   find 15: " .. tree:find(15))
        
    print("\n8) remove first key:")
    tree:remove(tree:first())
    travel_tree(tree, "   ")

    print("\n9) test walk")
    io.write("   ")    
    for k, _ in tree:walk() do
        io.write(k .. "(" .. tree:height(k) .. "), ")
    end
    print("")

    print("\n10) test walk reverse")
    io.write("   ")
    for k, _ in tree:walk(false) do
        io.write(k .. "(" .. tree:height(k) .. "), ")
    end
    print("")
    
    print("\n11) test range (2, 4)")
    io.write("   ")
    for _, k in ipairs(tree:range(2, 4)) do
        io.write(k .. "(" .. tree:height(k) .. "), ")
    end
    print("")

    print("\n12) test range (5, 3)")
    io.write("   ")
    for _, k in ipairs(tree:range(5, 3)) do
        io.write(k .. "(" .. tree:height(k) .. "), ")
    end
    print("")

        
    print("\n13) clean tree")
    tree:clear()
    travel_tree(tree, "   : (travel tree) ")
    print("   count: " .. tree:count())
end
    
function test_performance(tree)
    print("\n14) test performance, every round 1,000,000, then clear")
    local round = 0
    local last = os.clock()
    local avg = 0
    while true do
        round = round + 1
        local loop = 1000000
        while loop > 0 do
            loop = loop - 1
            tree:insert(loop, 0)
        end
        tree:clear()
        local now = os.clock()
        local elapsed = now - last
        avg = avg + elapsed
        print("round " .. round .. ": " .. elapsed .. "s, avg: " .. (avg / round) .. "s")
        last = now
    end
end

function travel_tree(tree, prefix)
    local n = tree:first()
    local tbl = { [1] = prefix }
    repeat
        tbl[#tbl + 1] = tostring(n) .. "(" .. tree:height(n) .. "), "
        n = tree:next(n)
    until n == nil
    print(table.concat(tbl))
end

test_rebalance(tree)
test_find_delete_replace(tree)
test_performance(tree)