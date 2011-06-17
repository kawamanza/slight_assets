module SlightAssets
  class JsReducer
    BYTE_RANGE = 32..127
    BASE_NUMBER = BYTE_RANGE.count
    BYTE_COUNT = BASE_NUMBER + 3
    FETCH_RANGE = BASE_NUMBER ** 2
    LOOKUP_CHAR = "`"

    def compress(js_content, last_occurrences = true)
      content = reduce(js_content, last_occurrences)
      return js_content if content == js_content
      func = 'function(x){var b="",p=0,c,l,L=x.length,m="`";while(p<L)b+=(c=x[p++])!=m?c:(l=x.charCodeAt(p++)-28)>4?b.substr(b.length-x.charCodeAt(p++)*96-x.charCodeAt(p++)+3104-l,l):m;return b}'
      content = content.gsub(/([\\"])/, '\\\\\\1').gsub(/\r/, "\\r").gsub(/\n/, "\\n")
      "eval((#{func})(\"#{content}\"))"
    end

    def reduce(js_content, last_occurrences = true)
      content = str_as_utf8(js_content)
      return js_content if content.nil?
      output, index, limit = "", -1, content.size
      while (index+=1) < limit
        i, chars = -1, str_as_utf8("")
        cropindex, cropsize = nil, 0
        while (i+=1) < BYTE_COUNT && index + i < limit
          chars << content[index+i]
          next if chars.size < 5
          max_start = index - chars.size
          start = [0, max_start - FETCH_RANGE].max
          if (pos = content.index(chars, start)) && pos <= max_start
            cropindex, cropsize = pos, chars.size
          end
        end
        if cropindex.nil?
          output << content[index]
          output << " " if content[index] == LOOKUP_CHAR
        else
          if last_occurrences
            max_start = [0, index - cropsize].max
            chars = str_as_utf8(content[cropindex, cropsize])
            cropindex = pos while (pos = content.index(chars, cropindex + 1)) && pos <= max_start
          end
          output << LOOKUP_CHAR
          output << BYTE_RANGE.first - 4 + cropsize
          offset = (index - cropindex) - cropsize
          output << BYTE_RANGE.first + (offset / BASE_NUMBER)
          output << BYTE_RANGE.first + (offset % BASE_NUMBER)
          index += cropsize - 1
        end
      end
      output
    end

    if RUBY_VERSION =~ /\A1\.[0-8]/
      begin
        require "utf8"
        def str_as_utf8(str)
          str.as_utf8
        end
      rescue LoadError
        def str_as_utf8(str)
          a = str.is_a?(Array) ? str : str.scan(/./mu)
          class << a
            def index(chars, start)
              return nil if start >= size
              i, s, cs = start - 1, size, chars.size
              while (i+=1) < s
                next if self[i] != chars[0]
                return i if cs == 1
                j = 0
                while (j+=1) < cs && i + j < s
                  break if self[i+j] != chars[j]
                  return i if j + 1 == cs
                end
              end
            end
          end
          a
        end
      end
    else
      def str_as_utf8(str)
        str
      end  
    end
  end
end
