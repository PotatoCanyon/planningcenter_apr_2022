require_relative '../../test_helper'
require_relative '../lib/bowling'


class StandardRollParserTest < Minitest::Test
  def setup
    @parser = StandardRollParser.new
    @configs = [
      {num_triggering_rolls: 1, triggering_value: 11, num_rolls_to_score: 4},  # strike
      {num_triggering_rolls: 2, triggering_value: 11, num_rolls_to_score: 4},  # spare
      {num_triggering_rolls: 2, triggering_value:  8, num_rolls_to_score: 3},  # hug
      {num_triggering_rolls: 2, triggering_value:  0, num_rolls_to_score: 2} ] # open
  end

  def test_strike_with_all_bonus_rolls
    rolls = [11,12,13,14]
    expected = [1, 4, [11,12,13,14]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_strike_with_some_bonus_rolls
    rolls = [11,12]
    expected = [1, 4, [11,12]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_strike_without_bonus_rolls
    rolls = [11]
    expected = [1, 4, [11]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_spare_with_all_bonus_rolls
    rolls = [7,4,1,2]
    expected = [2, 4, [7,4,1,2]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_spare_with_some_bonus_rolls
    rolls = [7,4,1]
    expected = [2, 4, [7,4,1]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_strike_without_bonus_rolls
    rolls = [7,4]
    expected = [2, 4, [7,4]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_hug_with_all_bonus_rolls
    rolls = [4,4,1]
    expected = [2, 3, [4,4,1]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_hug_without_bonus_rolls
    rolls = [4,4]
    expected = [2, 3, [4,4]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end

  def test_open_frame
    rolls = [1,2]
    expected = [2, 2, [1,2]]

    assert_equal expected, @parser.parse(rolls: rolls, frame_configs: @configs)
  end
end


class LowballRollParserTest < Minitest::Test
  def setup
    @parser = LowballRollParser.new
  end

  def test_strike_with_all_bonus_rolls
    rolls = [0,1,2]
    expected = [1, 3, [10, 1, 2]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end

  def test_strike_with_some_bonus_rolls
    rolls = [0,1]
    expected = [1, 3, [10, 1]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end

  def test_strike_without_bonus_rolls
    rolls = [0]
    expected = [1, 3, [10]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end

  def test_spare_with_all_bonus_rolls
    rolls = [1,0,2]
    expected = [2, 3, [1, 9, 2]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end

  def test_spare_without_bonus_rolls
    rolls = [1,0]
    expected = [2, 3, [1,9]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end

  def test_open_frame
    rolls = [1,2]
    expected = [2, 2, [1,2]]

    assert_equal expected, @parser.parse(rolls: rolls)
  end
end


class TestParserWhichAlwaysReturnsTwoRollsOfOnePin
  def parse(rolls:, frame_configs:)
    [2,2,[1,1]]
  end
end

class VariantTest < Minitest::Test
  def setup
    @config = { :parser => "TestParserWhichAlwaysReturnsTwoRollsOfOnePin"}

    # Notice that the parser puts two rolls in a frame, so
    # an array with 5 things should get us 3 frames, the first two
    # of which have a score.
    @input_rolls = [nil] * 5
  end

  def test_first_frame
    f = Variant.new(config: @config).framify(@input_rolls).first
    assert_equal 2, f.score
  end

  def test_second_frame
    f = Variant.new(config: @config).framify(@input_rolls)[1]
    assert_equal 2, f.score
  end

  def test_last_frame
    f = Variant.new(config: @config).framify(@input_rolls).last
    assert_nil f.score
  end
end


class FramesTest < Minitest::Test
  def test_gutter_game
    rolls = [0] * 20
    assert_equal 0, Frames.for(rolls: rolls).score
  end

  def test_all_ones
    rolls = [1] * 20
    assert_equal 20, Frames.for(rolls: rolls).score
  end

  def test_one_spare
    rolls = [5, 5, 3] + [0] * 17
    assert_equal 16, Frames.for(rolls: rolls).score
  end

  def test_one_strike
    rolls = [10, 3, 4] + [0] * 16
    assert_equal 24, Frames.for(rolls: rolls).score
  end

  def test_perfect_game
    rolls = [10] * 12
    assert_equal 300, Frames.for(rolls: rolls).score
  end

  def test_final_spare
    rolls = [1] * 18 + [4,6,4]
    assert_equal 32, Frames.for(rolls: rolls).score
  end

  def test_scoring_partial_game_with_complete_frames
    rolls = [1] * 6
    assert_equal 6, Frames.for(rolls: rolls).score
  end

  def test_scoring_partial_game_with_incomplete_final_frame
    rolls = [1] * 5
    assert_equal 4, Frames.for(rolls: rolls).score
  end

  def test_scoring_partial_game_with_unfulfilled_strike
    rolls = [10] * 10
    assert_equal 240, Frames.for(rolls: rolls).score
  end

  def test_scoring_partial_game_with_unfulfilled_spare
    rolls = [5,5,6,4]
    assert_equal 16, Frames.for(rolls: rolls).score
  end
end


class FrameTest < Minitest::Test
  def test_sums_rolls_to_calculate_score
    assert_equal 160, Frame.new(normal_rolls: [10], bonus_rolls: [50,100]).score
  end
end


class DetailedScoresheetTest < Minitest::Test
  def setup
    @io = StringIO.new
  end

  def test_scoresheet_for_incomplete_game
    rolls  = (([10] * 3) + [1,2] + [3,3] + [4,0])
    frames = Frames.for(rolls: rolls)

    expected =
      "FRAME: |--1-----|--2-----|--3-----|--4-----|--5-----|--6-----|--7-----|--8-----|--9-----|-10-----|\n" +
      "PINS:  | 10.    | 10.    | 10.    |  1.  2 |  3.  3 |  4.  0 |   .    |   .    |   .    |   .    |\n" +
      "BONUS: | 10. 10 | 10.  1 |  1.  2 |   .    |   .    |   .    |   .    |   .    |   .    |   .    |\n" +
      "SCORE: | 30     | 21     | 13     |  3     |  6     |  4     |        |        |        |        |\n" +
      "TOTAL: | 30     | 51     | 64     | 67     | 73     | 77     |        |        |        |        |\n"

    DetailedScoresheet.new(frames: frames, io: @io).render
    assert_equal expected, @io.string
  end

  def test_scoresheet_for_complete_game
    rolls  = (([10] * 3) + [1,2] + [3,3] + [4,0] + [7,3] + ([3,4] * 3))
    frames = Frames.for(rolls: rolls)

    expected =
      "FRAME: |--1-----|--2-----|--3-----|--4-----|--5-----|--6-----|--7-----|--8-----|--9-----|-10-----|\n" +
      "PINS:  | 10.    | 10.    | 10.    |  1.  2 |  3.  3 |  4.  0 |  7.  3 |  3.  4 |  3.  4 |  3.  4 |\n" +
      "BONUS: | 10. 10 | 10.  1 |  1.  2 |   .    |   .    |   .    |  3.    |   .    |   .    |   .    |\n" +
      "SCORE: | 30     | 21     | 13     |  3     |  6     |  4     | 13     |  7     |  7     |  7     |\n" +
      "TOTAL: | 30     | 51     | 64     | 67     | 73     | 77     | 90     | 97     |104     |111     |\n"

    DetailedScoresheet.new(frames: frames, io: @io).render
    assert_equal expected, @io.string
  end

  def test_scoresheet_for_complete_game_of_three_roll_frames
    rolls  = (([10] * 3) + [1,2,3] + [3,3,0] + [4,0,0] + [7,3] + ([3,4,1] * 3))
    frames = Frames.for(rolls: rolls, config: Variant::CONFIGS[:DUCKPIN])

    expected =
    "FRAME: |--1---------|--2---------|--3---------|--4---------|--5---------|--6---------|--7---------|--8---------|--9---------|-10---------|\n" +
    "PINS:  | 10.   .    | 10.   .    | 10.   .    |  1.  2.  3 |  3.  3.  0 |  4.  0.  0 |  7.  3.    |  3.  4.  1 |  3.  4.  1 |  3.  4.  1 |\n" +
    "BONUS: | 10. 10.    | 10.  1.    |  1.  2.    |   .   .    |   .   .    |   .   .    |  3.   .    |   .   .    |   .   .    |   .   .    |\n" +
    "SCORE: | 30         | 21         | 13         |  6         |  6         |  4         | 13         |  8         |  8         |  8         |\n" +
    "TOTAL: | 30         | 51         | 64         | 70         | 76         | 80         | 93         |101         |109         |117         |\n"

    DetailedScoresheet.new(frames: frames, io: @io).render
    assert_equal expected, @io.string
  end
end

class GameTest < Minitest::Test
  def test_prompts_for_player_names
    input  = StringIO.new("\n\n")
    output = StringIO.new
    player_name_prompt = "\nWho's playing? (Larry, Curly, Moe) >"

    Game.new(input: input, output: output)
    assert_equal player_name_prompt, output.string
  end
end
