phife.txt: qtip.txt
	echo $(basename $<): `cat $<` | tee $@
	echo $(basename $@): All the time $(basename $<) | tee -a $@
qtip.txt:
	echo You on point phife? > $@

.PHONY:
clean:
	-rm -rf phife.txt qtip.txt
