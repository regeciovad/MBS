# FLP projekt za rok 2016/2017
# Funcionalni projekt v jazyce Haskell
# Varianta rv-2-rka
# Vypracovala Dominika Regeciova, xregec00

EXECUTABLE=rv-2-rka

default: clean $(EXECUTABLE)

$(EXECUTABLE):
	ghc --make -Wall  $@.hs -o $@

doc:
	haddock -h --odir=doc $(EXECUTABLE).hs

clean:
	rm -rf *.o *hi $(EXECUTABLE)
