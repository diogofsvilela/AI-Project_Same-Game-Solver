from search import *

def board_find_groups(board):
	numLines = len(board)
	numColumns = len(board[0])
	numGroups = 0
	groups = []

	for lineIndex in range(numLines):
		lineGroups = []
		numGroupsInLine = 0
		lineGroups.append([numGroups, numGroupsInLine, board[lineIndex][0], (lineIndex, 0)])
		numGroups += 1
		numGroupsInLine += 1
		for columnIndex in range(1, numColumns):
			if board[lineIndex][columnIndex - 1] == board[lineIndex][columnIndex]:
				lineGroups[-1].append((lineIndex, columnIndex))
			else:
				lineGroups.append([numGroups, numGroupsInLine, board[lineIndex][columnIndex], (lineIndex, columnIndex)])
				numGroups += 1
				numGroupsInLine += 1

		groups.append(lineGroups)

	for lineIndex in range(len(groups) - 1):
		columnIndex = 0
		upGroupIndexLine = 0
		downGroupIndexLine = 0

		while columnIndex < numColumns:
			upGroup = groups[lineIndex][upGroupIndexLine]
			downGroup = groups[lineIndex + 1][downGroupIndexLine]
			if upGroup[2] == downGroup[2]:
				downGroup[0] = upGroup[0]
				if pos_c(downGroup[-1]) < pos_c(upGroup[-1]):
					downGroupIndexLine += 1
					columnIndex = pos_c(downGroup[-1]) + 1
				elif pos_c(downGroup[-1]) > pos_c(upGroup[-1]):
					upGroupIndexLine += 1
					columnIndex = pos_c(upGroup[-1]) + 1
				else:
					downGroupIndexLine += 1
					upGroupIndexLine += 1
					columnIndex = pos_c(downGroup[-1]) + 1
			else:
				columnIndex += 1
				if pos_c(downGroup[-1]) < columnIndex:
					downGroupIndexLine += 1
				if pos_c(upGroup[-1]) < columnIndex:
					upGroupIndexLine += 1

	groupsDict = {}

	for line in groups:
		for group in line:
			if group[0] in groupsDict:
				groupsDict[group[0]].extend(group[3:])
			else:
				groupsDict[group[0]] = group[3:]

	finalGroups = []

	for group in groupsDict:
		if board[groupsDict[group][0][0]][groupsDict[group][0][1]]:
			finalGroups.append(groupsDict[group])
	
	return finalGroups

# COLOR SECTION

def get_no_color():
	return 0


def no_color(c):
	return c == 0


def color(c):
	return c > 0


# POS SECTION
def make_pos(l, c):
	return (l, c)


def pos_l(pos):
	return pos[0]


def pos_c(pos):
	return pos[1]

def board_remove_group(board, group):
	'''Removes group from board'''

	group = sorted(group, key=lambda pos: pos_l(pos))  # Remove the top ones first

	numLines = len(board)
	numColumns = len(board[0])
	boardCopy = [[i for i in line] for line in board]
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

# CLASS sg_state

class sg_state():

	__slots__ = ('board',)

	def __init__(self, board):
		self.board = board

	def get_board(self):
		return self.board

	def __lt__(self, otherState):
		return 0

class same_game(Problem):
	"""Models a Same Game problem as a satisfaction problem.
		A solution cannot have pieces left on the board."""

	def __init__(self, board):
		super().__init__(sg_state(board))

	def actions(self, state):
		actions = list(filter(lambda x: len(x) > 1, board_find_groups(state.get_board())))
		return actions

	def result(self, state, action):
		return sg_state(board_remove_group(state.get_board(), action))

	def goal_test(self, state):
		for line in state.get_board():
			for c in line:
				if color(c):
					return False
		return True

	def h(self, node):
		return len(board_find_groups(node.state.get_board()))
