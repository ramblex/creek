require 'nokogiri'

module Creek
  class Creek::SAXParser < Nokogiri::XML::SAX::Document
    def initialize(enumerator, book)
      @enumerator = enumerator
      @book = book
    end

    def start_element(name, attrs = [])
      case name
      when 'row'
        @cells = {}
      when 'c'
        hash = attrs.to_h
        @cell = hash['r'].tr('0-9', '')
        @cell_type = hash['t']
        @cell_style_idx = hash['s']
      when 'v'
        @read_value = true
      end
    end

    def end_element(name)
      case name
      when 'row'
        @enumerator << @cells
      when 'v'
        @cells[@cell] = convert(@value, @cell_type, @cell_style_idx)
        @read_value = false
      end
    end

    def characters(str)
      if @read_value
        @value = str
      end
    end

    def convert(value, type, style_idx)
      style = @book.style_types[style_idx.to_i]
      Creek::Styles::Converter.call(value, type, style, converter_options)
    end

    def converter_options
      @converter_options ||= {
        shared_strings: @book.shared_strings.dictionary,
        base_date: @book.base_date
      }
    end
  end
end
