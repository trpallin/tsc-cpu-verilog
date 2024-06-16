`define PERIOD1 100
`define READ_DELAY 30 // delay before memory data is ready
`define WRITE_DELAY 30 // delay in writing to memory
`define MEMORY_SIZE 256 // size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16 // instead of 2^16 words to reduce memory
`define BTB_SIZE 1024 // branch target buffer size
`define BTB_TAG_SIZE 6 // branch target buffer tag size
`define BTB_INDEX_SIZE 10 // branch target buffer index size
`define MEMORY_LATENCY 4 // memory read/write latency (1~7)
`define CACHE_INDEX_SIZE 4 // cache index size
`define CACHE_BLOCK_SIZE 4 // cache block size
`define CACHE_TAG_BIT 12 // cache tag bit size
`define CACHE_INDEX_BIT 2 // cache index bit size
`define CACHE_BLOCK_BIT 2 // cache block bit size

`define NUM_TEST 56
`define TESTID_SIZE 5