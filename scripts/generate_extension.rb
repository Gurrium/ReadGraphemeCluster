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

File.open(File.join(File.dirname(__FILE__), "tmp.txt")) do |f|
  f.each_line do |l|
    captures = l.match(/^([\h\.]+)\s+; (\w+)/)&.captures
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

  puts <<"EXTENSION"
extension GraphemeClusterBreak {
    // ref: https://www.unicode.org/Public/UCD/latest/ucd/auxiliary/GraphemeBreakProperty.txt
    func match(_ scalar: UnicodeScalar) -> Bool {
        switch self {
EXTENSION

  rules.each do |property_value, test|
    puts <<"CASE"
        case .#{keys[property_value]}: // #{property_value}
            return #{test.join(" ||\n                    ")}
CASE
  end

  puts <<"OTHERS"
        case .any, .eBase, .eModifier, .glueAfterZWJ, .eBaseGAZ:
            return true
        case .sot, .eot:
            return false
OTHERS

  puts <<"EXTENSION"
        }
    }
}
EXTENSION
end
