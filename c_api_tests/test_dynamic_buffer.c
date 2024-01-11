#include <assert.h>
#include <stdint.h>
#include <stdlib.h>

#include "tfhe-c-api-dynamic-buffer.h"

int free_buffer(uint8_t *pointer, size_t length)
{
    free(pointer);
}

int main(int argc, char *argv[])
{
    size_t buffer_size = 100;
    uint8_t *buffer = malloc(buffer_size);
    assert(buffer != NULL);

    DynamicBuffer dyn_buffer = {.pointer = buffer, .length = buffer_size, .destructor = free_buffer};

    int ok = destroy_dynamic_buffer(&dyn_buffer);

    assert(ok == 0);
    assert(dyn_buffer.pointer == NULL);
    assert(dyn_buffer.length == 0);
    assert(dyn_buffer.destructor == NULL);

    return EXIT_SUCCESS;
}
