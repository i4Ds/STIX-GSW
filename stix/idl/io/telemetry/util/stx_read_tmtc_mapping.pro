function stx_read_tmtc_mapping
  tmtc_mappings = read_csv(concat_dir(getenv('STX_TMTC'),'tmtc_packet_mapping.csv'), header=tmtc_mappings_header, count=n_tmtc_mappings)
  tmtc_mappings_header = strlowcase(tmtc_mappings_header)
  
  mapping_strs = replicate(stx_telemetry_common_packet_header(), n_tmtc_mappings)
  mapping_strs.pid = tmtc_mappings.(where(tmtc_mappings_header eq 'pid'))
  mapping_strs.packet_category = tmtc_mappings.(where(tmtc_mappings_header eq 'packet_category'))
  mapping_strs.service_type = tmtc_mappings.(where(tmtc_mappings_header eq 'service_type'))
  mapping_strs.service_subtype = tmtc_mappings.(where(tmtc_mappings_header eq 'service_subtype'))
  mapping_strs.sid = tmtc_mappings.(where(tmtc_mappings_header eq 'sid'))
  mapping_strs.ssid = tmtc_mappings.(where(tmtc_mappings_header eq 'ssid'))
  mapping_strs.stx_tmtc_str = tmtc_mappings.(where(tmtc_mappings_header eq 'stx_tmtc_structure'))
  
  return, mapping_strs
end