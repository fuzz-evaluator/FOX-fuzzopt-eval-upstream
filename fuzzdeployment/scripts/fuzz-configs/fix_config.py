import argparse
import json
import os
import traceback

BASELINE = "baseline"
CMPLOG = "cmplog"
CMPLOG_DICT = "cmplog_dict"
OPTFUZZ = "optfuzz"
OPTFUZZ_DICT = "optfuzz_dict"

LIMITED_TARGETS = {
    "freetype",
    "libpng",
    "mbedtls",
    "bsdtar",
    "objdump",
    "strip-new"
}

BUILD_DIR_NAME = {
    BASELINE: "/binaries/aflpp_build",
    CMPLOG: "/binaries/aflpp_build",
    CMPLOG_DICT: "/binaries/aflpp_build",
    OPTFUZZ: "/binaries/optfuzz_build",
    OPTFUZZ_DICT: "/binaries/optfuzz_build"
}

FUZZER_NAME = {
    BASELINE: "aflpp",
    CMPLOG: "cmplog",
    CMPLOG_DICT: "cmplog_dict",
    OPTFUZZ: "optfuzz",
    OPTFUZZ_DICT: "optfuzz_dict"
}

JOB_COUNT = {
    "full": 10,
    "limited": 3
}

FUZZ_TIMEOUT = {
    "full": "86400",
    "limited": "1200"
}

ACCEPTED_MARGS = {
    BASELINE: {"", "-t 1000+"},
    CMPLOG: {"", "-t 1000+"},
    CMPLOG_DICT: {"", "-t 1000+"},
    OPTFUZZ: {"-k -p wd_scheduler", "-k -p wd_scheduler -t 1000+"},
    OPTFUZZ_DICT: {"-k -p wd_scheduler", "-k -p wd_scheduler -t 1000+"}
}

REQ_CONFIG_KEYS = {"mode", "input", "target", "cmdline", "output", "fuzztimeout", "fuzzer", "jobcount", "afl_margs", "env"}

CMDLINES = {
    "readelf": "-a @@",
    "xmllint": "@@",
    "pdftotext": "@@",
    "tcpdump": "-ee -vv -nnr @@",
    "bsdtar": "-xf @@ -O",
    "nm-new": "-C @@",
    "objdump": "-Dx @@",
    "size": "@@",
    "strip-new": "@@",
    "ffmpeg": "-i @@ test",
    "tiff2pdf": "@@",
    "exiv2": "pr @@",
    "jasper": "--input @@ --output test.bmp",
    "tiff2ps": "@@",
    "tiffcrop": "@@ out_1"
}

CMDLINE_TARGETS = list(CMDLINES.keys())


def parse_args():
    parser = argparse.ArgumentParser(description='Fix a config file.')
    parser.add_argument("--raw_configs", type=str, default="raw_configs", help="The directory containing the raw configs.")
    parser.add_argument("--full_configs", type=str, default="full_configs", help="The directory containing the full configs.")
    parser.add_argument("--limited_configs", type=str, default="limited_configs", help="The directory containing the sample run configs.")
    parser.add_argument("--limited_all_configs", type=str, default="limited_all_configs", help="The directory containing the extended sample run configs.")
    parser.add_argument("--merge", action="store_true", help="Merge the full and sample run configs.")
    return parser.parse_args()


def get_targets(raw_configs_path: str) -> list[str]:
    return [f.replace(".config.json", "") for f in os.listdir(raw_configs_path) if f.endswith(".config.json")]


def main(args: argparse.Namespace):
    os.makedirs(args.full_configs, exist_ok=True)
    os.makedirs(args.limited_configs, exist_ok=True)
    os.makedirs(args.limited_all_configs, exist_ok=True)

    targets = get_targets(args.raw_configs)
    num_validation_failures = 0
    for target in targets:
        print(f'Fixing {target}...')
        with open(os.path.join(args.raw_configs, f"{target}.config.json"), 'r') as f:
            config = json.load(f)

        modes = {c["mode"]: c for c in config if target in c["target"]}

        if OPTFUZZ in modes:
            for k, v in modes[OPTFUZZ].items():
                if isinstance(v, str):
                    if "optfuzz_nogllvm" in v:
                        modes[OPTFUZZ][k] = v.replace("optfuzz_nogllvm", "optfuzz")

        if OPTFUZZ_DICT in modes:
            for k, v in modes[OPTFUZZ_DICT].items():
                if isinstance(v, str):
                    if "optfuzz_dict_nogllvm" in v:
                        modes[OPTFUZZ_DICT][k] = v.replace("optfuzz_dict_nogllvm", "optfuzz_dict")
                    if "optfuzz_nogllvm_dict" in v:
                        modes[OPTFUZZ_DICT][k] = v.replace("optfuzz_nogllvm_dict", "optfuzz_dict")

        progress = True
        while progress:
            progress = False

            if OPTFUZZ not in modes and OPTFUZZ_DICT in modes:
                print(f"Adding optfuzz mode to {target}")
                optfuzz = {
                    "mode": OPTFUZZ,
                    "input": modes[OPTFUZZ_DICT]["input"],
                    "target": modes[OPTFUZZ_DICT]["target"],
                    "cmdline": modes[OPTFUZZ_DICT]["cmdline"],
                    "output": modes[OPTFUZZ_DICT]["output"].replace("optfuzz_dict", "optfuzz"),
                    "fuzztimeout": modes[OPTFUZZ_DICT]["fuzztimeout"],
                    "fuzzer": modes[OPTFUZZ_DICT]["fuzzer"],
                    "jobcount": modes[OPTFUZZ_DICT]["jobcount"],
                    "afl_margs": modes[OPTFUZZ_DICT]["afl_margs"],
                    "env": modes[OPTFUZZ_DICT]["env"],
                }
                modes[OPTFUZZ] = optfuzz
                progress = True

            if CMPLOG not in modes and CMPLOG_DICT in modes:
                print(f"Adding cmplog mode to {target}")
                cmplog = {
                    "mode": CMPLOG,
                    "input": modes[CMPLOG_DICT]["input"],
                    "target": modes[CMPLOG_DICT]["target"],
                    "cmplog_target": modes[CMPLOG_DICT]["cmplog_target"],
                    "cmdline": modes[CMPLOG_DICT]["cmdline"],
                    "output": modes[CMPLOG_DICT]["output"].replace("cmplog_dict", "cmplog"),
                    "fuzztimeout": modes[CMPLOG_DICT]["fuzztimeout"],
                    "fuzzer": modes[CMPLOG_DICT]["fuzzer"],
                    "jobcount": modes[CMPLOG_DICT]["jobcount"],
                    "afl_margs": modes[CMPLOG_DICT]["afl_margs"],
                    "env": modes[CMPLOG_DICT]["env"],
                }
                modes[CMPLOG] = cmplog
                progress = True

            if BASELINE not in modes and CMPLOG_DICT in modes:
                print(f"Adding baseline mode to {target}")
                baseline = {
                    "mode": BASELINE,
                    "input": modes[CMPLOG_DICT]["input"],
                    "target": modes[CMPLOG_DICT]["target"],
                    "cmdline": modes[CMPLOG_DICT]["cmdline"],
                    "output": modes[CMPLOG_DICT]["output"].replace("cmplog_dict", "aflpp"),
                    "fuzztimeout": modes[CMPLOG_DICT]["fuzztimeout"],
                    "fuzzer": modes[CMPLOG_DICT]["fuzzer"],
                    "jobcount": modes[CMPLOG_DICT]["jobcount"],
                    "afl_margs": modes[CMPLOG_DICT]["afl_margs"],
                    "env": modes[CMPLOG_DICT]["env"],
                }
                modes[BASELINE] = baseline
                progress = True
    
            if CMPLOG_DICT not in modes and OPTFUZZ_DICT in modes:
                print(f"Adding cmplog_dict mode to {target}")
                cmplog_dict = {
                    "mode": CMPLOG_DICT,
                    "input": modes[OPTFUZZ_DICT]["input"],
                    "target": modes[OPTFUZZ_DICT]["target"].replace("optfuzz", "aflpp"),
                    "cmplog_target": modes[OPTFUZZ_DICT]["target"].replace("optfuzz", "cmplog"),
                    "cmdline": modes[OPTFUZZ_DICT]["cmdline"],
                    "output": modes[OPTFUZZ_DICT]["output"].replace("optfuzz_dict", "cmplog_dict"),
                    "fuzztimeout": modes[OPTFUZZ_DICT]["fuzztimeout"],
                    "fuzzer": "/workspace/AFLplusplus/afl-fuzz",
                    "jobcount": modes[OPTFUZZ_DICT]["jobcount"],
                    "afl_margs": "",
                    "env": modes[OPTFUZZ_DICT]["env"],
                }
                for k, v in modes[OPTFUZZ_DICT].items():
                    if "dictionary" in k:
                        cmplog_dict[k] = v

                modes[CMPLOG_DICT] = cmplog_dict
                progress = True

        try: 
            validate(target, modes, run_kind="full")
        except Exception as e:
            print(f"Failed to validate {target}")
            print(traceback.format_exc())
            num_validation_failures += 1
            continue

        new_config = [modes[m] for m in [BASELINE, CMPLOG, OPTFUZZ, CMPLOG_DICT, OPTFUZZ_DICT]]


        with open(os.path.join(args.full_configs, f"{target}.config.json"), 'w') as f:
            json.dump(new_config, f, indent=4)

        for i, config in enumerate(new_config):
            new_config[i]["jobcount"] = JOB_COUNT["limited"]
            new_config[i]["fuzztimeout"] = FUZZ_TIMEOUT["limited"]
            
        validate(target, {c["mode"]: c for c in new_config}, run_kind="limited")

        with open(os.path.join(args.limited_all_configs, f"{target}.config.json"), 'w') as f:
            json.dump(new_config, f, indent=4)

        if target in LIMITED_TARGETS:
            with open(os.path.join(args.limited_configs, f"{target}.config.json"), 'w') as f:
                json.dump(new_config, f, indent=4)


    print(f"Fixed {len(targets) - num_validation_failures}/{len(targets)} configs.")

    if args.merge:
        print("Merging full and sample run configs...")
        full_targets = get_targets(args.full_configs)
        full_configs = []
        for target in full_targets:
            with open(os.path.join(args.full_configs, f"{target}.config.json"), 'r') as f:
                full_configs.extend(json.load(f))
        
        with open("../full.config.json", 'w') as f:
            json.dump(full_configs, f, indent=4)

        limited_targets = get_targets(args.limited_configs)
        limited_configs = []
        for target in limited_targets:
            with open(os.path.join(args.limited_configs, f"{target}.config.json"), 'r') as f:
                limited_configs.extend(json.load(f))

        with open("../limited.config.json", 'w') as f:
            json.dump(limited_configs, f, indent=4)

        limited_all_targets = get_targets(args.limited_all_configs)
        limited_all_configs = []
        for target in limited_all_targets:
            with open(os.path.join(args.limited_all_configs, f"{target}.config.json"), 'r') as f:
                limited_all_configs.extend(json.load(f))

        with open("../limited_all.config.json", 'w') as f:
            json.dump(limited_all_configs, f, indent=4)

def validate(target: str, modes: dict[str | int], run_kind: str):
        should_contain = {BASELINE, CMPLOG, OPTFUZZ, CMPLOG_DICT, OPTFUZZ_DICT}
        contains = set(modes.keys())
        missing = should_contain - contains

        afl_margs_baseline = set()
        afl_margs_optfuzz = set()
        dict_counts = set()
        cmdlines = set()
        inputs = set()

        if len(missing) > 0:
            raise ValueError(f"Missing mode in {target}: {missing}")
        
        for mode, config in modes.items():
            if mode == BASELINE:
                is_binutils_or_libtiff = "binutils" in config["target"] or "libtiff" in config["target"]
                target_dir = config["target"].replace("/workspace/fuzzopt-eval/fuzzdeployment", "../..")
                target_dir = "/".join(target_dir.split("/")[:-4 if is_binutils_or_libtiff else -3])
                target_build_script = f"{target_dir}/build_aflpp.sh"
                if not os.path.exists(target_build_script):
                    raise ValueError(f"Missing build script in {target} for {mode} in {target_build_script}")
                if not os.path.exists(f"{target_dir}/dict"):
                    with open(target_build_script, 'r') as f:
                        found_mkdir_p_dict = any("mkdir -p dict" in line for line in f)
                        if not found_mkdir_p_dict:
                            raise ValueError(f"Missing mkdir -p dict in {target} for {mode} in {target_build_script}")


            if not set(config.keys()).issuperset(REQ_CONFIG_KEYS):
                raise ValueError(f"Missing keys in {target} for {mode}")

            if BUILD_DIR_NAME[mode] not in config["target"]:
                raise ValueError(f"Invalid build dir in {target} for {mode}")
            
            if mode in {CMPLOG_DICT, OPTFUZZ_DICT}:
                if "dictionary" not in config:
                    raise ValueError(f"Missing dictionary in {target} for {mode}")
                dict_counts.add(len([k for k in config if "dictionary" in k]))

            if config["afl_margs"] not in ACCEPTED_MARGS[mode]:
                raise ValueError(f"Invalid afl_margs in {target} for {mode}")

            if f"{target}_{FUZZER_NAME[mode]}" not in config["output"]:
                print(config["output"])
                raise ValueError(f"Invalid output in {target} for {mode}")
                
            if len(config["env"]) != 1 and "AFL_NO_UI" not in config["env"] and config["AFL_NO_UI"] != "1":
                raise ValueError(f"Invalid env in {target} for {mode}")
            
            if config["jobcount"] != JOB_COUNT[run_kind]:
                raise ValueError(f"Invalid jobcount in {target} for {mode}")
            
            if config["fuzztimeout"] != FUZZ_TIMEOUT[run_kind]:
                raise ValueError(f"Invalid fuzztimeout in {target} for {mode}")
        
            if any(tgt in target for tgt in CMDLINE_TARGETS):
                if config["cmdline"] != CMDLINES[target]:
                    raise ValueError(f"Invalid cmdline in {target} for {mode}")
            elif config["cmdline"] != "":
                raise ValueError(f"Invalid cmdline in {target} for {mode}")

            if mode in {BASELINE, CMPLOG, CMPLOG_DICT}:
                afl_margs_baseline.add(config["afl_margs"])
            else:
                afl_margs_optfuzz.add(config["afl_margs"])
            inputs.add(config["input"])
            cmdlines.add(config["cmdline"])

        if len(afl_margs_baseline) > 1:
            raise ValueError(f"AFL margs mismatch in {target}")
        
        if len(afl_margs_optfuzz) > 1:
            raise ValueError(f"AFL margs mismatch in {target}")

        if len(inputs) > 1:
            raise ValueError(f"Input mismatch in {target}")
        
        if len(cmdlines) > 1:
            raise ValueError(f"Cmdline mismatch in {target}")
        
        if len(dict_counts) > 1:
            raise ValueError(f"Dictionary count mismatch in {target}")
        

if __name__ == '__main__':
    main(parse_args())