require 'rest_client'

class Hangman
    attr_reader :phrase

    PHRASES = [
        "mas vale pajaro en mano que cien volando local",
    	"al que madruga dios lo ayuda local",
    	"no por tanto madrugar amanece mas temprano local",
    	"mas sabe el diablo por viejo que por diablo local"
    ]

    ACCENTS = {"á" => "a", "Á" => "a", "é" => "e", "É" => "e", "í" => "i", "Í" => "i", "ó" => "o", "Ó" => "o", "Ú" => "u", "ú" => "u"}
    PLACEHOLDER = '_'

	def initialize phrase = nil
        if phrase.nil?
            phrase_index = rand(PHRASES.length()-1)
            @phrase = PHRASES[phrase_index]

            url = "http://#{ENV['PHRASES_HOST']}:#{ENV['PHRASES_PORT']}/phrases/random"
            r = RestClient::Request.execute(method: :get, url: url, timeout: 5) rescue nil
            @phrase = r.body if r &&  r.code == 200
        else
          @phrase = phrase
        end
        @correct_guesses = []
        @correct_guesses_by_word = []
        @missed_letters = []
        @remaining_fail_attempts = 6
        @game_status = :playing
	end

	def show_dashes
        by_letter = @phrase.chars.map { |c|
            if @correct_guesses.include? c.downcase
                c
            else
                c != ' ' ? PLACEHOLDER : ' '
            end
        }.join

        by_word = @phrase.split.map { |word|
          if @correct_guesses_by_word.include? word.downcase
            word
          else
            PLACEHOLDER * word.length
          end
        }.join(' ')

        by_letter.chars.zip(by_word.chars).map { |a, b|
          if a == b
            a == ' ' ? '   ' : a + ' '
          elsif b == PLACEHOLDER
            a + ' '
          else
            b + ' '
          end
        }.join
	end

    def guess(letter)
        unless ACCENTS[letter].nil?
            letter = ACCENTS[letter]
        end

        if (letter =~ /^[a-zA-ZñÑáÁ]+$/).nil?
            return "not a valid character"
        end

        if letter.length > 1
            return guess_by_word(letter)
        end

        if @phrase.downcase.include?(letter.downcase)
            @correct_guesses << letter.downcase
            @game_status = :won if !show_dashes().include? PLACEHOLDER
            return "excellent!"
        else
            letter_to_save = letter.downcase
            unless @missed_letters.include?(letter_to_save)
                @missed_letters << letter_to_save
                @remaining_fail_attempts -= 1 if @remaining_fail_attempts > 0
                @game_status = :lost if @remaining_fail_attempts == 0
            end
            return "miss"
        end

        return "unexepected error"
    end

    def missed_letters
        return @missed_letters.join(',')
    end

    def remaining_fail_attempts
        @remaining_fail_attempts
    end

    def game_status
        @game_status
    end

    private
    def guess_by_word(word)
        if @phrase.downcase.split.include?(word.downcase)
            @correct_guesses_by_word << word.downcase
            return "excellent!"
        else
            word_to_save = word.downcase
            unless @missed_letters.include?(word_to_save)
                @missed_letters << word_to_save
                @remaining_fail_attempts -= 1 if @remaining_fail_attempts > 0
                @game_status = :lost if @remaining_fail_attempts == 0
            end
            return "miss"
        end
    end
end
