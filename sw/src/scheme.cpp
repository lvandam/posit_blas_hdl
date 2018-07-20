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
        std::shared_ptr<arrow::DataType> type_ = arrow::int32();

        std::shared_ptr<arrow::ListBuilder> builder1_, builder2_;
        std::unique_ptr<arrow::ArrayBuilder> tmp1, tmp2;

        MakeBuilder(pool, arrow::list(type_), &tmp1);
        MakeBuilder(pool, arrow::list(type_), &tmp2);

        builder1_.reset(static_cast<arrow::ListBuilder*>(tmp1.release()));
        builder2_.reset(static_cast<arrow::ListBuilder*>(tmp2.release()));

        arrow::Int32Builder* vb1 = static_cast<arrow::Int32Builder*>(builder1_->value_builder());
        arrow::Int32Builder* vb2 = static_cast<arrow::Int32Builder*>(builder2_->value_builder());

        builder1_->Reserve(1);
        vb1->Reserve(vector1.size());
        builder1_->Append(1);
        for(posit<NBITS, ES>& el : vector1) {
                t_32 value_tmp;
                value_tmp.b = el.get().to_ulong();
                vb1->Append(value_tmp.b);
        }

        builder2_->Reserve(1);
        vb2->Reserve(vector2.size());
        builder2_->Append(1);
        for(posit<NBITS, ES>& el : vector2) {
                t_32 value_tmp;
                value_tmp.b = el.get().to_ulong();
                vb2->Append(value_tmp.b);
        }

        // Define the schema
        vector<shared_ptr<arrow::Field> > schema_fields = {
                arrow::field("element1", arrow::list(type_), false),
                arrow::field("element2", arrow::list(type_), false)
        };

        const std::vector<std::string> keys = {"fletcher_mode"};
        const std::vector<std::string> values = {"read"};
        auto schema_meta = std::make_shared<arrow::KeyValueMetadata>(keys, values);

        auto schema = std::make_shared<arrow::Schema>(schema_fields, schema_meta);

        // Create an array and finish the builder
        std::shared_ptr<arrow::Array> array1, array2;
        builder1_->Finish(&array1);
        builder2_->Finish(&array2);

        // Create and return the table
        return move(arrow::Table::Make(schema, { array1, array2 }));
}
