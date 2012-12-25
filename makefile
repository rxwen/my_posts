src_files = $(wildcard *.markdown)
html_files = $(patsubst %.markdown,%.html,$(src_files))
dot_files = $(wildcard *.dot)
png_files = $(patsubst %.dot,%.png,$(dot_files))

all: $(html_files)

$(html_files) : %.html : %.markdown
	markdown_py -f $@ < $<
	firefox $@

png: $(png_files)

$(png_files) : %.png : %.dot
	dot -T png -o $@ $<
	eog $@
