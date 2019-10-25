module SLURM


"""
    SLURM.arrayjob

A template for an array job, starting multiple serial jobs.

Requires:
- `jobname::String`: The name displayed in the queue
- `mail_types::Iterable{String}`: Events which trigger an email. (NONE, BEGIN, END, FAIL, ALL)
- `mail_user::String`: E-Mail adress to use
- `mem`: Memory limit of the job (Int64 or String)
- `time::String`: Time limit of the job (hrs:min:sec)
- `array::String`: E.g. "1-10", "0, 4, 8"
- `modules::String`: E.g. "module load julia1.2.0" or "", can be multiline
- `julia::String`: Path to julia
- `julia_args::String`: arguments to pass to julia
- `julia_script::String`: Path to the script to execute
- `args::String`: Arguments passed to the julia script
"""
const arrayjob = """
#!/bin/bash
#SBATCH --job-name=\$jobname
#SBATCH --mail-type=\$(join(mail_types, ","))
#SBATCH --mail-user=\$mail_user
#SBATCH --ntasks=1
#SBATCH --mem=\$mem
#SBATCH --time=\$time
#SBATCH --array=\$array

\$modules

\$julia \$julia_args \$julia_script \$args
"""


"""
    SLURM.chunked_serial_job

A template for an chunked serial job.

Requires:
- `mem`: Memory limit of the job (Int64 or String)
- `time::String`: Time limit of the job (hrs:min:sec)
- `account::String`: Accoutn name.
- `partition::String`: Partition to use.
- `nodes`: Number of nodes.
- `ntasks_per_node`: Number of tasks per node.
- `julia::String`: Path to julia
- `julia_args::String`: arguments to pass to julia
- `julia_script::String`: Path to the script to execute
- `args::String`: Arguments passed to the julia script
"""
const chunked_serial_job = """
#!/bin/bash -l
#SBATCH --time=\$time
#SBATCH --account=\$account
#SBATCH --partition=\$partition
#SBATCH --mem=\$mem
#SBATCH --nodes=\$nodes
#SBATCH --ntasks-per-node=\$ntasks_per_node

\$julia \$julia_args \$julia_script \$args
"""

end
