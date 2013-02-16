# Check the Rhime
phife.txt: qtip.txt
	echo $(basename $<): `cat $<` | tee $@
	echo $(basename $@): All the time $(basename $<) | tee -a $@
qtip.txt:
	echo You on point phife? > $@

# Can I kick it?
crowdagain.txt: crowd.txt qtipsoloagain.txt
	cat $< | tee $@
	echo $(basename $(lastword $^)): `cat $(lastword $^)` | tee -a $@
	echo $(basename $@): YES YOU CAN! | tee -a $@
qtipsoloagain.txt: 
	echo Can I KICK it? > $@
crowd.txt: qtipsolo.txt
	echo $(basename $<): `cat $<` | tee $@
	echo $(basename $@): Yes you can! | tee -a $@
qtipsolo.txt:
	echo Can I kick it? > $@


.PHONY:
clean:
	-rm -rf phife.txt qtip.txt crowdagain.txt qtipsolo.txt qtipsoloagain.txt crowd.txt
