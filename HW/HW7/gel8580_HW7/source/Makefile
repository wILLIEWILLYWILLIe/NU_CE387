
CC = gcc
CFLAGS = -O2 -Wall
LDFLAGS = -lm

TARGET = fft_quant
SRC = fft_quant.c

ALL: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) fft_in_*.txt fft_out_*.txt
