
all: clean cordic_ref run

cordic_ref: cordic.cpp
	g++ -o cordic_ref cordic.cpp -lm

run: cordic_ref
	./cordic_ref

clean:
	rm -f cordic_ref rad.txt sin.txt cos.txt
