'''
This module creates a bash script to run single-core campaigns as specified by
a configuration file
'''

import argparse
import json
import os
import subprocess
import sys
import greenstalk
import time
import pprint
import psutil

# Specify where the beanstalk server is running
HOST="127.0.0.1"
PORT="11300"

# Specify the max number of single-core campaigns to be allowed
# to be run at any given time
MAX_JOBS=None
# Records the number fo server screen sessions which need to be discounted when calculating 
# the actual number of campaigns that are running
# MAX_JOBS=2
# Specify (in seconds) the polling interval for available cores
TIMEOUT=1800
# Specify the time between jobs being deployed (in seconds)
JOB_INTERVAL=5
# TIMEOUT=30

def read_config(config_file):
    config_file = os.path.abspath(os.path.expanduser(config_file))

    if not os.path.isfile(config_file):
        print("Config file not found!")
        sys.exit(1)

    with open(config_file, "r") as f:
        config = json.load(f)

        return config

def afl_cmdline_from_config(config_settings, instance_number):
    afl_cmdline = ['timeout %s' % (config_settings["fuzztimeout"]), config_settings["fuzzer"]]

    # If we are running cmplog mode we need to add path to the cmplog binary as part
    # of fuzzer invocation and the corresponding dictionary as well
    if config_settings["mode"] == "cmplog" or config_settings["mode"] == "cmplog_dict" or config_settings["mode"] == "hastefuzz_cmplog" or config_settings["mode"] == "hastefuzz_cmplog_dict":
        afl_cmdline.append("-c")
        assert os.path.isfile(config_settings["cmplog_target"]), "Cmplog build target does not exist"
        afl_cmdline.append(config_settings["cmplog_target"])
    if config_settings["mode"] == "optfuzz_dict" or config_settings["mode"] == "cmplog_dict" or config_settings["mode"] == "aflpp_dict" or config_settings["mode"] == "hastefuzz_cmplog_dict":
        assert os.path.isfile(config_settings["dictionary"]), "Dictionary file does not exist"
        afl_cmdline.append("-x")
        afl_cmdline.append(config_settings["dictionary"])
        assert os.path.isfile(config_settings["dictionary"])
        # Add target-specific dictionary as well
        if "dictionary_2" in config_settings:
            afl_cmdline.append("-x")
            afl_cmdline.append(config_settings["dictionary_2"])
            assert os.path.isfile(config_settings["dictionary_2"])

    if "mem_limit" in config_settings:
        afl_cmdline.append("-m")
        afl_cmdline.append(config_settings["mem_limit"])

    if "afl_margs" in config_settings:
        afl_cmdline.append(config_settings["afl_margs"])

    if "input" in config_settings:
        afl_cmdline.append("-i")
        assert os.path.isdir(config_settings["input"]), "Seed dir does not exist"
        afl_cmdline.append(config_settings["input"])

    # Create instance-specific output directory 
    if "output" in config_settings:
        afl_cmdline.append("-o")
        assert not os.path.isdir(config_settings["output"] + "_%03d" % instance_number), "The output dir already exists please fix"
        afl_cmdline.append(config_settings["output"] + "_%03d" % instance_number)
    
    if config_settings["mode"] == "hastefuzz_cmplog" or config_settings["mode"] == "hastefuzz_cmplog_dict" or config_settings["mode"] == "hastefuzz_baseline":
        afl_cmdline.append("-u")
        afl_cmdline.append("-")

    return afl_cmdline


def build_target_cmd(conf_settings):
    target_cmd = [conf_settings["target"], conf_settings["cmdline"]]
    target_cmd = " ".join(target_cmd).split()
    target_cmd[0] = os.path.abspath(os.path.expanduser(target_cmd[0]))
    assert os.path.isfile(target_cmd[0]), "Aflpp build does not exist"
    target_cmd = " ".join(target_cmd)
    return target_cmd


def build_fuzz_cmd(conf_settings, instance_number, target_cmd):
    # compile command-line for fuzz instance 
    # $ afl-fuzz -i <input_dir> -o <output_dir> -- </path/to/target.bin> <target_args>
    tmp_cmd = afl_cmdline_from_config(conf_settings, instance_number)
    tmp_cmd += ["--", target_cmd]
    fuzz_cmd = " ".join(tmp_cmd)
    return fuzz_cmd  

def main():
    parser = argparse.ArgumentParser(description="Creates bash script to run fuzzing instances in parallel")
    parser.add_argument("-c", 
            "--config", 
            dest = "config_file",
            help = "Config file for fuzzing experiment", 
            default = None
            )
    parser.add_argument("-d",
            "--dry",
            dest = "is_dry",
            action = "store_true",
            default = False,
            help = "Run in dry mode")
    parser.add_argument("-n",
            "--numcores",
            dest = "numcores",
            type = int,
            required = True,
            help = "Specify the number of cores that are available for fuzzing. We recommend setting it to `nprocs`-1")
    parser.add_argument("--put",
            action = "store_true",
            help = "Put jobs in the beanstalk queue as specified in the config file")
    parser.add_argument("--get",
            action = "store_true",
            help = "Get jobs from the beanstalk queue")
    parser.add_argument("--flush",
            action = "store_true",
            help = "Flush jobs from the beanstalk queue")
            

    args = parser.parse_args()
    global MAX_JOBS
    MAX_JOBS = args.numcores
    
    if args.config_file:
        conf_settings = read_config(os.path.abspath(os.path.expanduser(args.config_file)))
    
    if args.put:
        # Iterate through each job and put them on the queue
        for item in conf_settings:
            put(item, args.is_dry)
    elif args.get:
        get(args.is_dry)
    elif args.flush:
        flush()
    else:
        print ("[X] Unknown mode passed (get/push/flush)")
        exit(1)

def put(conf_settings, isdry):
    global HOST, PORT

    # Get the Beanstalk queue 
    queue = greenstalk.Client(
            (HOST, int(PORT)), 
            use = 'jobs', watch = ['jobs'])

    # Create jobs and put them in the queue
    conf_settings["output"] = os.path.abspath(os.path.expanduser(conf_settings["output"]))

    target_cmd = build_target_cmd(conf_settings)
    for i in range(0, conf_settings["jobcount"]):
        job = {}
        # If we are running optfuzz then we need to cd into the build
        # dir before running the campaign
        if (conf_settings["mode"] == "optfuzz" or conf_settings["mode"] == "optfuzz_dict"):
            job["workdir"] = os.path.dirname(conf_settings["target"]) 
            job["cmd"] = [build_fuzz_cmd(conf_settings, i, target_cmd)]
        else:
            job["cmd"] = [build_fuzz_cmd(conf_settings, i, target_cmd)]
        job["env"] = conf_settings["env"]
        job["outdir"] = conf_settings["output"] + "_%03d" % i
        if isdry:
            print ("[X] Putting job:\n")
            pprint.pprint(job)
        else:
            print ("[X] Putting job:\n")
            pprint.pprint(job)
            queue.put(json.dumps(job))

def get(is_dry):
    global HOST, PORT, MAX_JOBS, TIMEOUT, JOB_INTERVAL

    # Get the Beanstalk queue 
    queue = greenstalk.Client(
            (HOST, int(PORT)), 
            use = 'jobs', watch = ['jobs'])

    while True:
        print("=================")
        active_jobs = get_running_jobs()
        assert active_jobs <= MAX_JOBS, 'More screen sessions exist than allowed to be spawned. Please investigate further'

        # If the ready queue is empty just exit
        stats = queue.stats_tube('jobs')
        if not stats["current-jobs-ready"]:
            print ('[X] No jobs left in queue')
            exit(0)

        # Check if all available cores occupied (as per MAXJOBS) and there are still jobs waiting to be finished
        if (active_jobs == MAX_JOBS):
            print ('[X] All available cores occupied..sleeping for %d seconds' % (TIMEOUT)) 
            print ('[X] Jobs remaining to be completed:', queue.stats_tube('jobs')["current-jobs-ready"])
            # Sleep and check back again
            time.sleep(TIMEOUT) 
            continue

        job = queue.reserve()
        queue.bury(job)
        current = json.loads(job.body)
        cmd_strings, env, outdir = current["cmd"], current["env"], current["outdir"]
        for cmd in cmd_strings:
            # Deploy fuzzer
            final_cmd = " ".join(['screen -d -m', cmd])

            # Setup environment variables
            base_env = os.environ.copy()
            for key, val in env.items():
                base_env[key] = val

            # Deploy the campaign
            if is_dry:
                print ("[X] Creating outdir\n")
                print ('mkdir -p %s\n' % outdir)
                print("[X] Getting job:\n")
                print(final_cmd)
            else:
                print ("\nCreating outdir:%s" % (outdir))
                os.makedirs(outdir) 
                # If we are running optfuzz we will have the workdir where we need to cd into
                if "workdir" in current:
                    workdir = current["workdir"]
                    print ("\nChanging workdir to %s for optfuzz" % (workdir))
                    os.chdir(workdir)
                print ("\nDeploying: %s" % (final_cmd))
                subprocess.Popen(final_cmd, env = base_env, shell = True)
                # Insert sleep to ensure that server has enough time to get setup before the fuzzer is run 
                time.sleep(JOB_INTERVAL)

def get_running_jobs():
    '''
    Gets the number of active fuzzcampaigns
    '''
    count = 0
    while True:
        count = 0
        try:
            for p in psutil.process_iter():
                if 'screen' in p.name(): 
                    count += 1
            break
        except psutil.NoSuchProcess:
            print ('[X] Error occurred...counting processes again')
            pass
    return count 

def flush():
    global HOST, PORT

    # Get the Beanstalk queue location
    queue = greenstalk.Client(
            (HOST, int(PORT)), 
            use = 'jobs', watch = ['jobs'])

    stats = queue.stats_tube('jobs')
    print (stats)
    for idx in range(0, stats['current-jobs-ready']):
        job = queue.reserve()
        queue.delete(job)
    if stats['current-jobs-buried']:
        queue.kick(stats['current-jobs-buried'])
        for idx in range(0, stats['current-jobs-ready']):
            job = queue.reserve()
            queue.delete(job)


if __name__ == "__main__":
    main()
