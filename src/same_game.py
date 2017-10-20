from search import *

##############################################################
#	
#	SAME GAME https://goo.gl/ta5CNq
#	IST IA 17/18 - GROUP TG028 DIOGO VILELA 84710, DIOGO REDIN 84711
#
#	SameGame is played on a board with colored pieces randomly placed. 
# 	By selecting a group pieces of the same color,they can be removed 
# 	from the field. Pieces that are no longer supported will fall down, 
# 	and a column without blocks will be  trimmed by other columns that 
# 	always slide to one side. The goal of this variant to remove all 
# 	pieces from the board.
#
##############################################################

class sg_state():
	'''Represents a same game board.'''

	__slots__ = ('board',)

	def __init__(self, board):
		self.board = board

	def get_board(self):
		return self.board

	def __lt__(self, otherState):
		return 0

##############################################################
#
#	SAME GAME SOLVER
#
##############################################################

class same_game(Problem):
	'''Models a same game problem as a satisfaction problem.
		A solution cannot have pieces left on the board.'''

	def __init__(self, board):
		super().__init__(sg_state(board))

	def actions(self, state):
		actions = list(filter(lambda x: len(x) > 1,
                        board_find_groups(state.get_board())))
		return actions

	def result(self, state, action):
		return sg_state(board_remove_group(state.get_board(), action))

	# Tests if the cell is filled or not
	def goal_test(self, state):
		return state.get_board()[-1][0] == 0

	def h(self, node):
		return len(board_find_groups(node.state.get_board()))

##############################################################
#
#	COLOR METHODS
#
##############################################################

def get_no_color():
	return 0

def no_color(c):
	return c == 0

def color(c):
	return c > 0

##############################################################
#
#	POSITION METHODS
#
##############################################################

def make_pos(l, c):
	return (l, c)

def pos_l(pos):
	return pos[0]

def pos_c(pos):
	return pos[1]

##############################################################
#
#	HEURISTIC AUX FUNCTION
#
##############################################################

def board_find_groups(board):
	'''Finds groups of blocks with the same colors. Pieces are
	considered a group when they are placed on top, left, right or bottom.
	Pieces on the diagonal aren't considered as being on the same group.'''

	# Contains the number of lines and columns on a board
	numLines = len(board)
	numColumns = len(board[0])

	# Groups found throughout the board
	numGroups = 0
	groups = []

	# Starts by iterating over each line. We start by grouping the groups found on a line
	# and only on the line below we join the group with existing groups.
	for lineIndex in range(numLines):

		# Stores the groups found and the number of groups in this line
		# An element in lineGroups has the form [indexOftheGroup, numGroupsInLine, color, (line, column)]
		lineGroups = []
		numGroupsInLine = 0

		# We always add the first element of a line (column = 0)
		lineGroups.append(
			[numGroups, numGroupsInLine, board[lineIndex][0], [], [], (lineIndex, 0)])

		# We added the first one so the number of groups incereased
		numGroups += 1
		numGroupsInLine += 1

		# We go through every element of the current line
		for columnIndex in range(1, numColumns):

			# Check if the element before (<-) has the same color
			if board[lineIndex][columnIndex - 1] == board[lineIndex][columnIndex]:
				lineGroups[-1].append((lineIndex, columnIndex))

			# If it doesn't we have a new group with a different color and the number of groups increased
			else:
				lineGroups.append([numGroups, numGroupsInLine, board[lineIndex]
                                    [columnIndex], [], [], (lineIndex, columnIndex)])
				numGroups += 1
				numGroupsInLine += 1

		# Adds the groups in this line to the total
		groups.append(lineGroups)

	# Goes through the groups found in each line to group current and bottom
	# This stracture has the form [[indexOftheGroup, numGroupsInLine, color, (line, column), (line, column)], ...] ...]]
	for lineIndex in range(len(groups) - 1):

		# Position from where we start on a line
		columnIndex = 0

		# Position from where we start on current and bottom line
		currentGroupIndexLine = 0
		downGroupIndexLine = 0

		# While we have columns to go thorugh on our list
		while columnIndex < numColumns:

			# Current line group and right on bottom group
			currentGroup = groups[lineIndex][currentGroupIndexLine]
			downGroup = groups[lineIndex + 1][downGroupIndexLine]

			# Checks if the color is the same
			if currentGroup[2] == downGroup[2]:

				# Re-assigns index of the group
				recursiveUpdate(downGroup, currentGroup[0], groups)
				recursiveUpdate(currentGroup, currentGroup[0], groups)
				downGroup[3].append((lineIndex, currentGroupIndexLine))
				currentGroup[4].append((lineIndex + 1, downGroupIndexLine))

				# Checks wether to process the current or bottom
				if pos_c(downGroup[-1]) < pos_c(currentGroup[-1]):
					downGroupIndexLine += 1
					columnIndex = pos_c(downGroup[-1]) + 1

				elif pos_c(downGroup[-1]) > pos_c(currentGroup[-1]):
					currentGroupIndexLine += 1
					columnIndex = pos_c(currentGroup[-1]) + 1

				else:
					downGroupIndexLine += 1
					currentGroupIndexLine += 1
					columnIndex = pos_c(downGroup[-1]) + 1

			else:
				columnIndex += 1

				if pos_c(downGroup[-1]) < columnIndex:
					downGroupIndexLine += 1

				if pos_c(currentGroup[-1]) < columnIndex:
					currentGroupIndexLine += 1

	# Concatenates Groups
	groupsDict = {}
	for line in groups:

		for group in line:

			if group[0] in groupsDict:
				groupsDict[group[0]].extend(group[5:])
			else:
				groupsDict[group[0]] = group[5:]

	finalGroups = []
	for group in groupsDict:
		if board[groupsDict[group][0][0]][groupsDict[group][0][1]]:
			finalGroups.append(groupsDict[group])

	return finalGroups

##############################################################
#
#	HEURISTIC AUX FUNCTION
#
##############################################################


def board_remove_group(board, group):
	'''Given a found grup of pieces removes it from the board.'''

	# Remove the top ones first
	group = sorted(group, key=lambda pos: pos_l(pos))

	numLines = len(board)
	numColumns = len(board[0])
	boardCopy = [[i for i in line] for line in board]

	# Doesnt change the original board
	for pos in group:

		line = pos_l(pos)
		column = pos_c(pos)
		boardCopy[line][column] = get_no_color()
		line -= 1

		while line >= 0 and color(boardCopy[line][column]):
			boardCopy[line + 1][column] = boardCopy[line][column]
			line -= 1

		boardCopy[line + 1][column] = 0

	for column in range(numColumns - 2, -1, -1):

		if not boardCopy[numLines - 1][column]:

			for line in range(0, numLines):
				boardCopy[line].pop(column)
				boardCopy[line].append(0)

	return boardCopy


def recursiveUpdate(group, value, groups):
	for (line, groupIndex) in group[3]:
		recursiveUpdate(groups[line][groupIndex], value, groups)
	for (line, groupIndex) in group[4]:
		groups[line][groupIndex][0] = value
	group[0] = value