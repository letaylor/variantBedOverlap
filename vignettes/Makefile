all:
	# to pdf
	R --slave -e 'rmarkdown::render("variantBedOverlap.Rmd", output_format ="rmarkdown::pdf_document")'
	# general html documnet --> better scrollable tables
	#R --slave -e 'rmarkdown::render("variantBedOverlap.Rmd", output_format ="rmarkdown::html_document")'
	# html document specifically formatted for vignette
	R --slave -e 'rmarkdown::render("variantBedOverlap.Rmd", output_format ="rmarkdown::html_vignette")'
	# to github formatted markdown
	R --slave -e 'rmarkdown::render("variantBedOverlap.Rmd", output_format ="rmarkdown::github_document")'

clean:
	rm -f variantBedOverlap.md variantBedOverlap.html variantBedOverlap.pdf
	rm -rf variantBedOverlap_files/