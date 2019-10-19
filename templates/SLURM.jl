module SLURM


"""
    SLURM.arrayjob

A template for an array job, starting multiple serial jobs.

Requires:
- `jobname::String`: The name displayed in the queue
- `mail_events::Iterable{String}`: Events which trigger an email. (NONE, BEGIN, END, FAIL, ALL)
- `mail::String`: E-Mail adress to use
- `memory`: Memory limit of the job (Int64 or String)
- `time::string`: Time limit of the job (hrs:min:sec)
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
#SBATCH --mail-type=\$(join(mail_events, ","))
#SBATCH --mail-user=\$mail
#SBATCH --ntasks=1
#SBATCH --mem=\$memory
#SBATCH --time=\$time
#SBATCH --array=\$array

\$modules

\$julia \$julia_args \$julia_script \$args
"""

end
