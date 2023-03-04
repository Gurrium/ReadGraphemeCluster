.PHONY: generate_match_extension
generate_match_extension:
	curl https://www.unicode.org/Public/UCD/latest/ucd/auxiliary/GraphemeBreakProperty.txt --output scripts/tmp.txt
	ruby scripts/generate_extension.rb > Sources/ReadGraphemeCluster/GraphemeCluterBreak+match.generated.swift
	rm scripts/tmp.txt
