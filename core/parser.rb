module Parser
	class Conversion
		def initialize(input, result)
			@input = input
			@result = result
		end
		def input
			@input
		end
		def input=(value)
			@input = value
		end
		def result
			@result
		end
		def result=(value)
			@result = value
		end
		def signature
			@input.gsub(/\[[a-z0-9 ]*\]/i, '[?]')
		end
	end
	class Result
		def initialize(tokens, action)
			@action = action
			@tokens = tokens
		end
		def action
			@action
		end
		def tokens
			@tokens
		end
	end
	@@commands = Hash.new
	@@syntaxes = Hash.new
	def self.fuck_you
		@@syntaxes.keys
	end
	def self.translate(input, result, overwrite = true)
		generic = input.gsub(/\[[a-z0-9_]*\]/i, '[?]')
		if (@@syntaxes[generic] != nil and overwrite)
			puts "Overwriting #{generic}"
			@@syntaxes[generic].input = input
			@@syntaxes[generic].result = result
		else
			words = input.split
			cmd = words[0]
			if @@commands.key?(cmd) == false
				@@commands[cmd] = Array.new
			end
			words = result.split
			if words.length > 3
				raise "Result of translation must have three tokens or less ('#{result} received)"
			end
			con = Conversion.new(input, result)
			@@commands[cmd].push(con)
			@@syntaxes[generic] = con
			@@commands[cmd].sort! { |a, b|
				b.input.split.length <=> a.input.split.length
			}
		end
		puts "Syntax: #{input}, #{result}, #{generic}"
		@@syntaxes[generic]
	end
	def self.commands
		@@commands.keys.sort
	end
	def self.syntaxes(cmd)
		@@commands[cmd] || []
	end
	def self.actions(command)
		result = Array.new
		inp = command.downcase.split
		cmd = inp.shift
		if @@commands.key?(cmd) == false
			return nil
		end
		@@commands[cmd].each { |con|
			puts "Parsing for #{con.input}"
			parts = con.input.split
			parts.shift
			puts "\tParts:#{parts.join('|')}"
			ii = 0
			variables = Hash.new
			thisXlation = ""
			match = true
			parts.each_index { |i|
				if parts[i][0, 1] == '['
					if i == parts.length - 1
						puts "We're at the last variable."
						variables[parts[i]] = inp.join(' ')
						match = true
						break
					else
						nothing_but_vars = true
						next_i = i + 1
						while (next_i < parts.length)
							if parts[next_i][0, 1] != '['
								nothing_but_vars = false
								break
							end
							next_i = next_i + 1
						end
						if nothing_but_vars
							variables[parts[i]] = inp.join(' ')
							match = true
							break
						else
							placeholder = Array.new
							local_match = false
							while (inp.length > 0)
								cur_word = inp.shift
								if cur_word == parts[i + 1]
									variables[parts[i]] = placeholder.join(' ')
									inp.unshift cur_word
									local_match = true
									break
								else
									placeholder.push cur_word
								end
							end
							if local_match == false
								match = false
								break
							end
						end
					end
				else
					if parts[i] == inp[0]
						inp.shift
					else
						match = false
						break
					end
				end
			}
			if match == true
				puts "Matched #{con.input} (#{con.signature})"
				input_sig = con.input.gsub(/\[[a-z0-9_]*\]/i, '[?]')
				if (Action[input_sig] != nil)
					puts "Got a signature"
					vars = Array.new
					con.result.split.each { |x|
						if x[0,1] == "[" and variables[x] != nil
							vars.push variables[x]
						end
					}
					if vars.length == 0 and inp != nil and inp.length > 0
						vars.push inp.join(' ')
					end
					puts "Vars to tokenize: #{vars.join('|')}, #{vars.length}"
					#puts "#{vars.class}"
					#result.push Action[con.signature]
					result.push Result.new(vars, Action[input_sig])
				else
					puts "No signature for #{input_sig}"
				end
				#result.push con
				#final = Array.new
				#con.result.split.each { |x|
				#	if x[0,1] == "["
				#		if (variables[x] != '')
				#			final.push(variables[x])
				#		else
				#			final.push(nil)
				#		end
				#	else
				#		final.push(x)
				#	end
				#}
				#return final
			end
		}
		return result
	end
end
