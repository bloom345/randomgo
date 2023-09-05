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
class OutOfBoardException < RuntimeError
  def initialize(message="coordinate of the move is out of board!")
    super(message)
  end
end

# 一手(x, y)に打つ
# COORDS指定時とそれ以外の共通プロセス
# @param [Fixnum] i; 手数（実際の手数-1）
# @param [String] current_stone; 黒か白か。"B"→黒、"W"→白
# @param [Fixnum] x_coord; x座標。左上始点の列座標 1始まり。
# @param [Fixnum] y_coord; y座標。左上始点の行座標 1始まり。
# @raise [BoardFullException] 打つ場所がないときに投げられる例外
# @raise [DuplicateException] 既に石が置かれているところに打とうとしたときに投げられる例外
def play(i, current_stone, x_coord, y_coord)
  raise OutOfBoardException if x_coord > BOARD_SIZE || y_coord > BOARD_SIZE
  raise BoardFullException if @amount_of_stones >= (BOARD_SIZE-2*(MIN-1)) ** 2
  new_pos = [x_coord, y_coord]
  raise DuplicateException if @positions.include?(new_pos)
  @amount_of_stones += 1
  @positions << new_pos
  print "#{i+1}:#{current_stone}#{new_pos}, "
  @board[x_coord-1][y_coord-1] = current_stone
  @sgf_string += "#{current_stone}[#{@num_to_alphabet[x_coord-1]}#{@num_to_alphabet[y_coord-1]}];"
end

#-----------------------------------------------------------------------------------
# 環境変数取得
FUSEKI_STONES_AMOUNT = (ENV["STONES"] || 10).to_i
BOARD_SIZE = (ENV["SZ"] || 13).to_i # ボードサイズ 最大19
MIN = (ENV["MIN"] || 2).to_i # MIN線以上に配置 MIN=3なら3線より上にしか配置しない
COORDS = ENV["COORDS"] # "B[aa];W[ab]; ..." という文字列
KOMI = (ENV["KM"] || 6.5).to_f
RULE = ENV["RU"] || "Japanese" # Japanese or Chinese
PB = ENV["PB"] || "black" # 黒番プレイヤー名
PW = ENV["PW"] || "white" # 白番プレイヤー名

# バリデーション
raise "Board size should be equal to or less than 19!" if BOARD_SIZE > 19
raise "Environment variable MIN should be less than half of board size!" if MIN > (BOARD_SIZE+1) / 2.0

max_coord = BOARD_SIZE - (MIN - 1)
@board = Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, '.')} 
@num_to_alphabet = (:a..:s).to_a # 座標→アルファベットの変換用配列
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
      x_coord = rand(MIN..max_coord)
      y_coord = rand(MIN..max_coord)
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
print "\n"
@board.transpose.each do |column|
  column.each { |e| print e }; print "\n"
end

@sgf_string += ")"
puts @sgf_string
filename ="random_SZ#{BOARD_SIZE}_NOS#{FUSEKI_STONES_AMOUNT}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.sgf" 
begin
  File.open(filename, "w") do |f|
    f.write(@sgf_string)
  end
  puts "Successfully output #{filename}"
rescue => e
  puts "Failed to output #{filename}"
  puts "ERROR: #{e.message}"
end
