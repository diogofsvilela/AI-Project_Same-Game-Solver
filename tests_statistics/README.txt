
No que é que cada teste foca:

# Test 01 a 04 - board_find_groups

# Test 05 a 14 - board_remove_group

# Test 15 a 16 - sg_state
# Test 15 - create sg_state
# Test 16 - access board of sg_state

# Test 17 a 32 - same_game
# Test 17 - same_game(board) type is same_game
# Test 18 - same_game.initial type is sg_state
# Test 19 - same_game.initial.board

# Test 20 - same_game.actions(initial.state)
# Test 21 - same_game.actions(initial.state)

# Test 22 - same_game.goal_test(initial.state)
# Test 23 - same_game.goal_test(initial.state)
# Test 24 - same_game.goal_test(initial.state)

# Test 25 - same_game.result(board, action)
# Test 26 - same_game.result(board, action)

# Test 27 - search result is an empty board
# Test 28 - Depth First Search 10x4 com 3 cores
# Test 29 - Depth First Search 4x5 com 2 cores sem solução
# Test 30 - Greedy search 10x4 com 3 cores
# Test 31 - A* 10x4 com 5 cores
# Test 32 - A* 10x15 com 3 cores


São usadas as seguintes funções cujo código não foi publicado:

1) xx_recursive_sort(<list of groups>)
   A função devolve uma lista de grupos equivalente mas com uma ordenação específica.

2) xx_invalid_solution(<board>, <result of search>)
   A função devolve False se o resultado da procura estiver correcto.
   Senão a função devolve uma mensagem de erro que tenta mostrar o que falhou.
   Por exemplo:
    - "A procura devia retornar um objecto do tipo Node e nao um do tipo <class 'int'> com valor 5"
    - "A accao 8 nao e valida <accao> A sequencia de accoes e: <seq de accoes>"
    - "O tabuleiro nao esta vazio: <board>"
