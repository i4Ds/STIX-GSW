function stx_date2elut_file, date

elut_index = loc_file( 'elut_index.csv', path = getenv('STX_DET'))

str_index = read_csv(elut_index, n_table_header = 1)

file_index = value_locate(anytim(str_index.FIELD2), anytim(date))

elut_filename = (str_index.FIELD4)[file_index]

return, elut_filename
end 