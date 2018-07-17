#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>

// Apache Arrow
#include <arrow/api.h>

#include "utils.hpp"

using namespace std;

/**
 * Create an Arrow table containing one column of elements
 */
shared_ptr<arrow::Table> create_table_elements(std::vector<uint32_t>& vector1, std::vector<uint32_t>& vector2)
{
    //
    // listprim(32)
    //
    arrow::MemoryPool* pool = arrow::default_memory_pool();
    std::shared_ptr<arrow::DataType> type_ = arrow::fixed_size_binary(32);

    arrow::BinaryBuilder el1_builder(type_, pool);
    for(uint32_t& el : vector1) {
        t_32 value_tmp;
        value_tmp.b = el;

        uint8_t element_bytes[4];
        element_bytes[0] = value_tmp.x[0];
        element_bytes[1] = value_tmp.x[1];
        element_bytes[2] = value_tmp.x[2];
        element_bytes[3] = value_tmp.x[3];

        el1_builder.Append(element_bytes, 4);
    }

    arrow::BinaryBuilder el2_builder(type_, pool);
    for(uint32_t& el : vector2) {
        t_32 value_tmp;
        value_tmp.b = el;

        uint8_t element_bytes[4];
        element_bytes[0] = value_tmp.x[0];
        element_bytes[1] = value_tmp.x[1];
        element_bytes[2] = value_tmp.x[2];
        element_bytes[3] = value_tmp.x[3];

        el2_builder.Append(element_bytes, 4);
    }

    // Define the schema
    vector<shared_ptr<arrow::Field> > schema_fields = {
        arrow::field("element1", arrow::fixed_size_binary(32), false),
        arrow::field("element2", arrow::fixed_size_binary(32), false)
    };

    const std::vector<std::string> keys = {"fletcher_mode"};
    const std::vector<std::string> values = {"read"};
    auto schema_meta = std::make_shared<arrow::KeyValueMetadata>(keys, values);

    auto schema = std::make_shared<arrow::Schema>(schema_fields, schema_meta);

    // Create an array and finish the builder
    shared_ptr<arrow::Array> el1_array, el2_array;
    el1_builder.Finish(&el1_array);
    el2_builder.Finish(&el2_array);

    // Create and return the table
    return move(arrow::Table::Make(schema, { el1_array, el2_array }));
}
