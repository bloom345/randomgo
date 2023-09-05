require 'date'
# 例外クラス定義
class BoardFullException < RuntimeError; end
class DuplicateException < RuntimeError; end

# COORDS指定時とそれ以外の共通プロセス
# TODO: メソッド名変更
def play(i, current_stone, x_coord, y_coord)
  if @amount_of_stones >= BOARD_SIZE ** 2
    raise BoardFullException.new("cannot put any more stones on the board!")
  end
  new_pos = [x_coord, y_coord]
  if @positions.include?(new_pos)
    raise DuplicateException.new("new move is duplicated and won't be placed on the board.")
  end
  @amount_of_stones += 1
  @positions << new_pos
  print "#{i+1}:#{current_stone}#{new_pos}, "
  @board[x_coord-1][y_coord-1] = current_stone
  @sgf_string += "#{current_stone}[#{@num_to_alphabet[x_coord-1]}#{@num_to_alphabet[y_coord-1]}];"
end

FUSEKI_STONES_AMOUNT = (ENV["STONES"] || 10).to_i
BOARD_SIZE = (ENV["SZ"] || 13).to_i
MIN = (ENV["MIN"] || 2).to_i
COORDS = ENV["COORDS"] # "B[aa];W[ab]; ..." という文字列
raise "Environment variable MIN should be less than half of board size!" if MIN > (BOARD_SIZE+1) / 2.0
max_coord = BOARD_SIZE - (MIN - 1)
@board = Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, '.')} 
@num_to_alphabet = (:a..:s).to_a # 座標→アルファベットの変換用配列
@positions = [] # 重複判定用
@sgf_string = "(;GM[1]SZ[#{BOARD_SIZE}]PB[black]PW[white]KM[6.5]RU[Japanese];"
@amount_of_stones = 0
if COORDS
  COORDS.split(";").each_with_index do |pos_str, i|
    begin 
      current_stone = pos_str[0]
      x_coord = @num_to_alphabet.index(pos_str[2].to_sym)+1
      y_coord = @num_to_alphabet.index(pos_str[3].to_sym)+1
      play(i, current_stone, x_coord, y_coord)
    rescue => e
      print e.message
      case e
      when BoardFullException
        break 
      when DuplicateException
        redo
      end
    end
  end
else
  (FUSEKI_STONES_AMOUNT*2).times do |i|
    begin
     current_stone = (i % 2 == 0) ? "B" : "W"
      x_coord = rand(MIN..max_coord)
      y_coord = rand(MIN..max_coord)
      play(i, current_stone, x_coord, y_coord)
    rescue => e
      print e.message
      case e
      when BoardFullException
        break
      when DuplicateException
        redo
      end
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
  puts "Succeeded to output #{filename}"
rescue => e
  puts "Failed to output #{filename}"
  puts "ERROR: #{e.message}"
end
