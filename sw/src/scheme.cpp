#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>
#include <posit/posit>

// Apache Arrow
#include <arrow/api.h>

#include "utils.hpp"

using namespace std;
using namespace sw::unum;

/**
 * Create an Arrow table containing one column of elements
 */
shared_ptr<arrow::Table> create_table_elements(std::vector<posit<NBITS, ES> >& vector1, std::vector<posit<NBITS, ES> >& vector2)
{
        //
        // listprim(32)
        //
        arrow::MemoryPool* pool = arrow::default_memory_pool();
        // std::shared_ptr<arrow::DataType> type_ = arrow::fixed_size_binary(4);

        // arrow::BinaryBuilder el1_builder(type_, pool);
        // uint8_t values1[vector1.size() * 4]; // = new uint8_t[vector1.size() * 4];
        // int val1_pos = 0;
        // for(posit<NBITS, ES>& el : vector1) {
        //     t_32 value_tmp;
        //     value_tmp.b = el.get().to_ulong();
        //
        //     // uint8_t values1[4]; // = new uint8_t[vector1.size() * 4];
        //     values1[val1_pos++] = value_tmp.x[0];
        //     values1[val1_pos++] = value_tmp.x[1];
        //     values1[val1_pos++] = value_tmp.x[2];
        //     values1[val1_pos++] = value_tmp.x[3];
        //
        //     // el1_builder.Append(values1, 8);
        // }
        // el1_builder.Append(values1, vector1.size()*4);
        // cout << "EL1 builder length: " << el1_builder.value_data_length() << endl;
        //
        // arrow::BinaryBuilder el2_builder(type_, pool);
        // uint8_t values2[vector2.size() * 4]; //= new uint8_t[vector2.size() * 4];
        // int val2_pos = 0;
        // for(posit<NBITS, ES>& el : vector2) {
        //     t_32 value_tmp;
        //     value_tmp.b = el.get().to_ulong();
        //
        //     // uint8_t values2[4]; //= new uint8_t[vector2.size() * 4];
        //     values2[val2_pos++] = value_tmp.x[0];
        //     values2[val2_pos++] = value_tmp.x[1];
        //     values2[val2_pos++] = value_tmp.x[2];
        //     values2[val2_pos++] = value_tmp.x[3];
        //
        //     // el2_builder.Append(values2, 8);
        // }
        // el2_builder.Append(values2, vector2.size()*4);
        // cout << "EL2 builder length: " << el2_builder.value_data_length() << endl;



        std::shared_ptr<arrow::DataType> type_ = arrow::int32();
        std::shared_ptr<arrow::ListBuilder> builder_;

        std::unique_ptr<arrow::ArrayBuilder> tmp;
        MakeBuilder(pool, arrow::list(type_), &tmp);
        builder_.reset(static_cast<arrow::ListBuilder*>(tmp.release()));

        arrow::Int32Builder* vb = static_cast<arrow::Int32Builder*>(builder_->value_builder());

        builder_->Reserve(1);
        vb->Reserve(vector2.size());

        builder_->Append(1);
        for(posit<NBITS, ES>& el : vector2) {
                t_32 value_tmp;
                value_tmp.b = el.get().to_ulong();

                vb->Append(value_tmp.b);
        }

        std::shared_ptr<arrow::Array> array;
        builder_->Finish(&array);












        // t_32 test_val;
        // test_val.x[0] = values2[vector2.size()*4-4];
        // test_val.x[1] = values2[vector2.size()*4-3];
        // test_val.x[2] = values2[vector2.size()*4-2];
        // test_val.x[3] = values2[vector2.size()*4-1];
        // cout << "LAST VAL VECTOR 2: " << setfill('0') << setw(8) << hex << test_val.b << dec << endl;

        // Define the schema
        // vector<shared_ptr<arrow::Field> > schema_fields = {
        //     arrow::field("element1", arrow::fixed_size_binary(4), false),
        //     arrow::field("element2", arrow::fixed_size_binary(4), false)
        // };

        vector<shared_ptr<arrow::Field> > schema_fields = {
                arrow::field("element1", arrow::list(type_), false),
                arrow::field("element2", arrow::list(type_), false)
        };

        const std::vector<std::string> keys = {"fletcher_mode"};
        const std::vector<std::string> values = {"read"};
        auto schema_meta = std::make_shared<arrow::KeyValueMetadata>(keys, values);

        auto schema = std::make_shared<arrow::Schema>(schema_fields, schema_meta);

        // Create an array and finish the builder
        // shared_ptr<arrow::Array> el1_array, el2_array;
        // el1_builder.Finish(&el1_array);
        // el2_builder.Finish(&el2_array);

        // Create and return the table
        // return move(arrow::Table::Make(schema, { el1_array, el2_array }));
        return move(arrow::Table::Make(schema, { array, array }));
}
