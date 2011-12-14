module SlightAssets
  class JsReducer
    BYTE_RANGE = 32..127
    BASE_NUMBER = BYTE_RANGE.count
    FETCH_RANGE = BASE_NUMBER ** 2
    LOOKUP_CHAR = "`"
    ESCAPABLE_CHARS = ["\\", "\"", "\r", "\n"].freeze

    def compress(js_content)
      content = reduce(js_content)
      return js_content if content == js_content
      func = 'function(x){var b="",p=0,c,l,L=x.length,m="`";while(p<L)b+=(c=x[p++])!=m?c:(l=x.charCodeAt(p++)-31)>1?b.substr(b.length-x.charCodeAt(p++)*96-x.charCodeAt(p++)+3104-l,l):m;return b}'
      content = content.gsub(/([\\"])/, '\\\\\\1').gsub(/\r/, "\\r").gsub(/\n/, "\\n")
      "eval((#{func})(\"#{content}\"))"
    end

    def reduce(js_content)
      max_cropsize = BASE_NUMBER
      content = str_as_utf8(js_content)
      return js_content if content.nil?
      output, index, limit = "", -1, content.size
      while (index+=1) < limit
        i, chars = -1, str_as_utf8("")
        cropindex, cropsize, s = nil, 0, 0
        while (i+=1) < max_cropsize && index + i < limit
          chars << (c = content[index+i])
          next if s < 5 && (s += (ESCAPABLE_CHARS.include?(c) ? 2 : c.bytesize) ) < 5
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
          max_start = [0, index - cropsize].max
          chars = str_as_utf8(content[cropindex, cropsize])
          cropindex = pos while (pos = content.index(chars, cropindex + 1)) && pos <= max_start
          output << LOOKUP_CHAR
          output << BYTE_RANGE.last - max_cropsize + cropsize
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
      rescue LoadError => e
        STDERR.puts "WARN: #{e.message}"
        def str_as_utf8(str)
        end
      end
    else
      def str_as_utf8(str)
        str
      end
    end
  end
end
