library verilog;
use verilog.vl_types.all;
entity dac_top_tb is
    generic(
        CYCLE           : integer := 20;
        RST_TIME        : integer := 3
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CYCLE : constant is 1;
    attribute mti_svvh_generic_type of RST_TIME : constant is 1;
end dac_top_tb;
