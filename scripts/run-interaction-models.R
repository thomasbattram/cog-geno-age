# ----------------------------------------------------------------------
# Run cog <- SNP:age models
# ----------------------------------------------------------------------

## aim: using a cognition variable, run a model testing for an 
##		interaction between two SNPs (individually) and age

## pkgs
library(tidyverse)
library(broom)
library(lubridate)

## args
UKB_GEN_DIR <- "" # ADD THIS IN
pc_file <- file.path(UKB_GEN_DIR, "derived/principal_components/data.pca1-10.plink.txt")
gen_file_snp1 <- "data/gen-data-chr2.raw"
gen_file_snp2 <- "data/gen-data-chr21.raw"
big_pheno_file <- "data/data.51913.csv"
pheno_file <- "data/pheno-data.tsv"
linker_file <- "data/linker.81499.csv"
res_outfile <- "results/regression-res.tsv"
char_outfile <- "results/characteristics.csv"

## data
if (!file.exists(pheno_file)) {
	select_func <- function(x, pos) dplyr::select(x, all_of(c("eid", "31-0.0", "34-0.0", "20136-0.0", "20156-0.0")))
	# test <- read_csv_chunked("data/pheno-data-first50-rows.csv", DataFrameCallback$new(select_func), chunk_size = 5)

	pheno_dat <- read_csv_chunked(big_pheno_file, DataFrameCallback$new(select_func), chunk_size = 1000)
	write.table(pheno_dat, file = pheno_file, quote = T, col.names = T, row.names = F, sep = "\t")	
}
pheno_dat <- read_tsv(pheno_file)
colnames(pheno_dat) <- c("eid", "sex", "dob", "trail_date", "trail_duration")

pc_dat <- read_delim(pc_file, delim = " ", col_names = FALSE)
colnames(pc_dat) <- c("FID", "IID", paste0("PC", 1:10))

linker <- read_csv(linker_file)

gen1 <- read_tsv(gen_file_snp1)
gen2 <- read_tsv(gen_file_snp2)

# ----------------------------------------------------------------------
# Tidy data and run some simple checks
# ----------------------------------------------------------------------

## combine all data together in one dataset
snp1 <- "rs34743896_T"
snp2 <- "rs35743227_T"
cols_to_keep <- c(colnames(pheno_dat), "ieu", paste0("PC", 1:10), snp1, snp2)

comb_dat <- pheno_dat %>%
	left_join(linker, by = c("eid" = "app")) %>%
	left_join(gen1, by = c("ieu" = "FID")) %>%
	left_join(gen2, by = c("ieu" = "FID")) %>%
	left_join(pc_dat, by = c("ieu" = "FID")) %>%
	dplyr::select(all_of(cols_to_keep))

## Check variables match with what is on the UKB showcase 
# field=20156 (https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=20156)
# 104,007 items of data are available, covering 104,007 participants.
# Mean = 39.194
# Std.dev = 14.9989
sum(!is.na(comb_dat$trail_duration)) # 104014
mean(comb_dat$trail_duration, na.rm=T) # 39.19372
sd(comb_dat$trail_duration, na.rm=T) # 14.99877

# field=20136 (https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=20136)
# 120,433 items of data are available, covering 120,433 participants.
# Mean = 2014-12-18
sum(!is.na(comb_dat$trail_date)) # 120441
mean(comb_dat$trail_date, na.rm=T) # 2014-12-18 06:29:04 UTC

## Extract just data of interest
trail_dat <- comb_dat %>%
	dplyr::filter(!is.na(trail_duration))

## Create age variable
trail_dat <- trail_dat %>%
	mutate(trail_year = year(trail_dat$trail_date)) %>%
	mutate(age = trail_year - dob)

# ----------------------------------------------------------------------
# Run regression
# ----------------------------------------------------------------------

# Model1 <- lm (outcome ~ age + sex + PC1……..PC10 + SNP1 + SNP1:age)
# Model2 <- lm (outcome ~ age + sex + PC1……..PC10 + SNP2 + SNP2:age)

## Using SNP 1 (rs34743896)
form1 <- as.formula(paste0("trail_duration ~ age + sex",
						  " + ", 
						  paste0("PC", 1:10, collapse = " + "), 
						  " + ",
						  snp1,
						  " + ",  
						  paste(c(snp1, "age"), collapse = ":")
						  )
					)

model1 <- lm(form1, data = trail_dat)

## Using SNP 2 (rs35743227)
form2 <- as.formula(paste0("trail_duration ~ age + sex",
						  " + ", 
						  paste0("PC", 1:10, collapse = " + "), 
						  " + ",
						  snp2,
						  " + ",  
						  paste(c(snp2, "age"), collapse = ":")
						  )
					)

model2 <- lm(form2, data = trail_dat)

## Tidy and output
reg_res1 <- broom::tidy(model1) %>%
	dplyr::filter(term %in% c("rs34743896_T", "age:rs34743896_T"))

reg_res2 <- broom::tidy(model2) %>%
	dplyr::filter(term %in% c("rs35743227_T", "age:rs35743227_T"))

comb_reg_res <- bind_rows(reg_res1, reg_res2) %>%
	dplyr::select(-statistic)

write.table(comb_reg_res, file = res_outfile, row.names = F, col.names = T, sep = "\t", quote = F)

# ----------------------------------------------------------------------
# Summarise individual characteristics
# ----------------------------------------------------------------------
trail_dat$rs34743896_T_BG <- round(trail_dat$rs34743896_T)
trail_dat$rs35743227_T_BG <- round(trail_dat$rs35743227_T)
trail_dat$sex <- ifelse(trail_dat$sex == 0, "F", "M")
t1_vars <- c("sex", "age", "trail_duration", "rs34743896_T", "rs35743227_T", "rs34743896_T_BG", "rs35743227_T_BG")
cat_vars <- c("sex", "rs34743896_T_BG", "rs35743227_T_BG")
tab1 <- CreateTableOne(data = trail_dat, vars = t1_vars, factorVars = cat_vars)
tab1_mat <- print(tab1, quote = FALSE, noSpaces = TRUE, printToggle = FALSE)
write.csv(tab1_mat, file = char_outfile)


