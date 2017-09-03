# FLP projekt za rok 2016/2017
# Logicky projekt v jazyce Prolog
# Varianta Patnactka
# Vypracovala Dominika Regeciova, xregec00

EXECUTABLE=flp17-log

default: clean $(EXECUTABLE)

$(EXECUTABLE):
	swipl -q -g start -o $(EXECUTABLE) -c $(EXECUTABLE).pl

clean:
	rm -rf $(EXECUTABLE) tests/res*
