require 'date'
# 例外クラス定義
class BoardFullException < Exception
  def initialize(message="cannot play any more moves!")
    super(message)
  end
end
class DuplicateException < Exception
  def initialize(message="new move is duplicated and won't be placed on the board.")
    super(message)
  end
end
class OutOfBoardException < Exception
  def initialize(message="coordinate of the move is out of board!")
    super(message)
  end
end

# (x, y)に指定の石を打つ
# @param [Fixnum] i; 手数（実際の手数-1）
# @param [String] current_stone; 黒か白か。"B"→黒、"W"→白
# @param [Fixnum] x_coord; x座標。左上始点の列座標 1始まり。
# @param [Fixnum] y_coord; y座標。左上始点の行座標 1始まり。
# @raise [OutOfBoardException] 座標でボードの外側を指定したときに投げられる例外
# @raise [BoardFullException] 打つ場所がないときに投げられる例外
# @raise [DuplicateException] 既に石が置かれているところに打とうとしたときに投げられる例外
def play(i, current_stone, x_coord, y_coord)
  raise OutOfBoardException if x_coord > BOARD_SIZE || y_coord > BOARD_SIZE
  raise BoardFullException if @amount_of_stones >= (MAX-MIN+1) ** 2
  new_pos = [x_coord, y_coord]
  raise DuplicateException if @positions.include?(new_pos)
  @amount_of_stones += 1
  @board[x_coord-1][y_coord-1] = current_stone
  no_of_breathing_points = search(x_coord-1, y_coord-1)
  puts "呼吸点=#{no_of_breathing_points}"
  show_board(@check)
  if no_of_breathing_points == 0
    puts "着手禁止点"
    @board[x_coord-1][y_coord-1] = "." # ロールバック
  else
    @positions << new_pos
    print "#{i+1}:#{current_stone}#{new_pos}, "
    @sgf_string += "#{current_stone}[#{@num_to_alphabet[x_coord-1]}#{@num_to_alphabet[y_coord-1]}];"
  end
  # TODO: capture 処理を加える。打った場所の四方の石についてそれぞれsearchして、呼吸点0なら取り除く。
end

def capture
  
end

def show_board(board=@board)
  print "\n"
  board.transpose.each do |column|
    column.each { |e| print e }; print "\n"
  end
end

# 座標を与えて、その座標にある石が属するグループの呼吸点の数を数える。
# @param [Fixnum] x_pos; 0始まりのx座標
# @param [Fixnum] y_pos; 0始まりのy座標
# @return [Fixnum] 呼吸点の数
def search(x_pos, y_pos, stone=nil)
  puts "searching (#{x_pos+1},#{y_pos+1})..."
  if x_pos < 0 || y_pos < 0 || x_pos >= BOARD_SIZE || y_pos >= BOARD_SIZE
    puts "return 0"
    return 0
  end
  pos = @board[x_pos][y_pos] 
  if stone == nil
    # 最初の呼び出し
    @check = Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, 0)} 
    return nil if pos == "." || pos == nil # ナンセンスなのでnilを返す
    # posは"B"か"W"
    @check[x_pos][y_pos] = pos
    search(x_pos+1, y_pos, pos) + search(x_pos, y_pos+1, pos) + search(x_pos-1, y_pos, pos) + search(x_pos, y_pos-1, pos) 
  else 
    if @check[x_pos][y_pos] != 0
      puts "return 0"
      return 0 
    end
    case pos
    when "."
      @check[x_pos][y_pos] = pos
      puts "return 1"
      1
    when stone
      @check[x_pos][y_pos] = pos
      search(x_pos+1, y_pos, pos) + search(x_pos, y_pos+1, pos) + search(x_pos-1, y_pos, pos) + search(x_pos, y_pos-1, pos) 
    when nil
      # 盤の範囲外
      puts "return 0"
      0
    else
      # 違う色の石
      @check[x_pos][y_pos] = pos
      puts "return 0"
      0
    end    
  end
end
#-----------------------------------------------------------------------------------
# 環境変数取得
FUSEKI_STONES_AMOUNT = (ENV["STONES"] || 10).to_i
BOARD_SIZE = (ENV["SZ"] || 13).to_i # ボードサイズ 最大19
MIN = (ENV["MIN"] || 2).to_i # MIN線以上に配置 MIN=3なら3線より上にしか配置しない
MAX = BOARD_SIZE-MIN+1 
COORDS = ENV["COORDS"] # "B[aa];W[ab]; ..." という文字列
KOMI = (ENV["KM"] || 6.5).to_f
RULE = ENV["RU"] || "Japanese" # Japanese or Chinese
PB = ENV["PB"] || "black" # 黒番プレイヤー名
PW = ENV["PW"] || "white" # 白番プレイヤー名

# バリデーション
raise "Board size should be equal to or less than 19!" if BOARD_SIZE > 19
raise "Environment variable MIN should be less than half of board size!" if MIN > MAX

# インスタンス変数初期化
@board = Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, '.')} 
@num_to_alphabet = (:a..:z).to_a # 座標→アルファベットの変換用配列
@positions = [] # 重複判定用
@sgf_string = "(;GM[1]SZ[#{BOARD_SIZE}]PB[#{PB}]PW[#{PW}]KM[#{KOMI}]RU[#{RULE}];"
@amount_of_stones = 0

if COORDS
  COORDS.split(";").each_with_index do |pos_str, i|
    begin 
      current_stone = pos_str[0]
      x_coord = @num_to_alphabet.index(pos_str[2].to_sym)+1
      y_coord = @num_to_alphabet.index(pos_str[3].to_sym)+1
      play(i, current_stone, x_coord, y_coord)
    rescue BoardFullException => e
      puts e.message
      break 
    rescue DuplicateException
      redo
    end
  end
else
  (FUSEKI_STONES_AMOUNT*2).times do |i|
    begin
     current_stone = (i % 2 == 0) ? "B" : "W"
      x_coord = rand(MIN..MAX)
      y_coord = rand(MIN..MAX)
      play(i, current_stone, x_coord, y_coord)
    rescue BoardFullException => e
      puts e.message
      break 
    rescue DuplicateException
      redo
    end
  end
end

# ボード簡易表示
show_board

@sgf_string += ")"
puts @sgf_string
filename ="sgf/random_SZ#{BOARD_SIZE}_NOS#{FUSEKI_STONES_AMOUNT}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.sgf" 
begin
  File.open(filename, "w") do |f|
    f.write(@sgf_string)
  end
  puts "Successfully output #{filename}"
rescue => e
  puts "Failed to output #{filename}"
  puts "ERROR: #{e.message}"
end
