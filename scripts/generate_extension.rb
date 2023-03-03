keys = {
  'Prepend' => 'prepend',
  'CR' => 'cr',
  'LF' => 'lf',
  'Control' => 'control',
  'Extend' => 'extend',
  'Regional_Indicator' => 'regionalIndicator',
  'SpacingMark' => 'spacingMark',
  'L' => 'l',
  'V' => 'v',
  'T' => 't',
  'LV' => 'lv',
  'LVT' => 'lvt',
  'ZWJ' => 'zwj'
}
rules = {}

File.open('tmp.txt') do |f|
  f.each_line do |l|
    captures = l.match(/^([\h\.]+)\s+; ([[:alpha:]]+)/)&.captures
    next if captures.nil?

    codepoints, property_value = captures
    codepoints = codepoints.split('..')
    test = ''
    if codepoints.count == 2
      test = "(0x#{codepoints[0]}...0x#{codepoints[1]}).contains(scalar.value)"
    else
      test = "scalar.value == 0x#{codepoints[0]}"
    end

    if rules[property_value]
      rules[property_value].append(test)
    else
      rules[property_value] = [test]
    end
  end

  // TODO: 適切な場所に配置する
  File.open('GraphemeClusterBreak+match.swift', 'w') do |out_file|
    out_file.puts <<"EXTENSION"
extension GraphemeClusterBreak {
    // ref: https://www.unicode.org/Public/UCD/latest/ucd/auxiliary/GraphemeBreakProperty.txt
    func match(_ scalar: UnicodeScalar) -> Bool {
        switch self {
EXTENSION

    rules.each do |property_value, test|
      out_file.puts <<"CASE"
            case #{keys[property_value]}: // #{property_value}
                return #{test.join(" ||\n                    ")}
CASE
    end

    out_file.puts <<"EXTENSION"
         }
     }
 }
EXTENSION
  end

  0
end
