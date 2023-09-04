require 'date'
FUSEKI_STONES_AMOUNT = (ENV["STONES"] || 10).to_i
BOARD_SIZE = (ENV["SZ"] || 13).to_i
MIN = (ENV["MIN"] || 2).to_i
COORDS = ENV["COORDS"] # "B[aa];W[ab]; ..." という文字列
raise "Environment variable MIN should be less than half of board size!" if MIN > (BOARD_SIZE+1) / 2.0
max_coord = BOARD_SIZE - (MIN - 1)
board = Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, '.')} 

# num_to_alphabet[num] = <alphabet>
num_to_alphabet = (:a..:s).to_a

positions = []
sgf_string = "(;GM[1]SZ[#{BOARD_SIZE}]PB[black]PW[white]KM[6.5]RU[Japanese];"
amount_of_stones = 0
if COORDS
  COORDS.split(";").each_with_index do |pos_str, i|
    # pos_str は、 B[aa] のような文字列
    if amount_of_stones >= BOARD_SIZE ** 2
      puts "cannot put any more stones on the board!"
      break
    end
    current_stone = pos_str[0]
    x_coord = num_to_alphabet.index(pos_str[2].to_sym)
    y_coord = num_to_alphabet.index(pos_str[3].to_sym)
    pos = [x_coord, y_coord]
    amount_of_stones += 1
    print "#{i+1}:#{current_stone}#{pos}, "
    board[x_coord][y_coord] = current_stone
    sgf_string += "#{pos_str};"
  end
else
  (FUSEKI_STONES_AMOUNT*2).times do |i|
    if amount_of_stones >= (max_coord - MIN + 1) ** 2
      puts "cannot put any more stones on the board!"
      break
    end
    current_stone = (i % 2 == 0) ? "B" : "W"
    new_pos = [rand(MIN..max_coord), rand(MIN..max_coord)]
    redo if positions.include?(new_pos)
    amount_of_stones += 1
    positions << new_pos
    print "#{i+1}:#{current_stone}#{new_pos}, "
    board[new_pos[0]-1][new_pos[1]-1] = current_stone
    sgf_string += "#{current_stone}[#{num_to_alphabet[new_pos[0]-1]}#{num_to_alphabet[new_pos[1]-1]}];"
  end
end
sgf_string += ")"

print "\n"
board.transpose.each do |column|
  column.each { |e| print e }; print "\n"
end

puts sgf_string
filename ="random_SZ#{BOARD_SIZE}_NOS#{FUSEKI_STONES_AMOUNT}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.sgf" 
begin
  File.open(filename, "w") do |f|
    f.write(sgf_string)
  end
  puts "Succeeded to output #{filename}"
rescue => e
  puts "Failed to output #{filename}"
  puts "ERROR: #{e.message}"
end
