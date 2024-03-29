#####PART 1 Proteomics#####
#####Differentially expressed protein
setwd("D:/R_Files")
library(openxlsx)
data=read.xlsx("PROTEIN_CHIP.xlsx")
library("DESeq2")
protein<-data[,c(11,16:ncol(data))]
rownames(protein)<-protein[,1]
protein2<-protein[,-1]
protein3<-t(protein2)
protein4=round(protein3)
group_list=c("Control","Control","Control","Control","Control","Control","Control","Control","Control","Control","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD","CAD")
(colData<-data.frame(row.names = colnames(protein4),
                     group_list=group_list))
dds<-DESeqDataSetFromMatrix(countData = protein4,
                            colData = colData,
                            design = ~group_list)
dds <-DESeq(dds)
res<-results(dds,
             contrast = c("group_list","CAD","Control"))
resOrdered <-res[order(res$padj),]
head(resOrdered)
DEG_SLE_aNB=as.data.frame(resOrdered)
write.csv(DEG_SLE_aNB,"DEPS.csv")


#####Volcano Plot
library(ggplot2)
library(ggpubr)
library(ggthemes)
setwd("D:/R_FILES")
data<-read.csv("DEPS.csv")
#log_transformation on P
data$"-log10Pvalue"<- -log10(data$pvalue)
#PLOT
ggscatter(data, x="log2FoldChange", y="-log10Pvalue")+theme_base()
#color,reference line
ggscatter(data, x="log2FoldChange", y="-log10Pvalue",color = "Group", palette = c("#2f5688","#BBBBBB","#CC0000"),size = 2)+theme_base()+geom_hline(yintercept = 1.30,linetype="dashed")+geom_vline(xintercept = c(-0.5,0.5),linetype="dashed")
#label
data$label<-""
upprotein<-data$X[which(data$Group=="up-regulated")]
downprotein<-data$X[which(data$Group=="down-regulated")]
significant_protein<-c(as.character(upprotein),as.character(downprotein))
data$label[match(significant_protein,data$X)]<-significant_protein
ggscatter(data, x="log2FoldChange", y="-log10Pvalue",color = "Group", palette = c("#2f5688","#BBBBBB","#CC0000"),size = 1, label=data$label,font.label=8, repel=T, xlab="log2(FoldChange)", ylab="-log10(P-value)",)+theme_base()+geom_hline(yintercept = 1.30,linetype="dashed")+geom_vline(xintercept = c(-0.5,0.5),linetype="dashed")



#####PART 2 MENDELIAN RANDOMIZATION#####
library(TwoSampleMR)
# CAD
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
ao <- available_outcomes()
outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('ieu-a-7'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
MR<-mr(dat, method_list=c("mr_wald_ratio"))
MR2<-mr(dat, method_list=c("mr_ivw_mre"))
MR3<-mr(dat, method_list=c("mr_ivw_fe"))
MR_Final<-rbind(MR,MR3[1,],MR2[c(2,3),])
MR_Final$OR<-exp(MR_Final$b)
MR_Final$L95<-exp(MR_Final$b-1.96*MR_Final$se)
MR_Final$H95<-exp(MR_Final$b+1.96*MR_Final$se)
MR_Final$fdr=p.adjust(MR_Final$pval, "BH")
write.csv(MR_Final, "MR_AGES_cardiogramplusc4d_result.csv")
write.csv(dat,"AGES_cardiogramplusc4d_dat.csv")


#####Sensitivity analysis#####
#####Other MR methodology
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('ieu-a-7'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
MR_Final<-mr(dat, method_list=c("mr_ivw_mre","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))
MR_Final$OR<-exp(MR_Final$b)
MR_Final$L95<-exp(MR_Final$b-1.96*MR_Final$se)
MR_Final$H95<-exp(MR_Final$b+1.96*MR_Final$se)
write.csv(MR_Final, "MR_result.csv")
library(MRPRESSO)
mr_presso(BetaOutcome = "beta.outcome", BetaExposure = "beta.exposure", SdOutcome = "se.outcome", SdExposure = "se.exposure", OUTLIERtest = TRUE, DISTORTIONtest = TRUE, data = dat, NbDistribution = 1000,  SignifThreshold = 0.05)
mr_heterogeneity(dat)
mr_pleiotropy_test(dat)

#####Other outcome
#####MI,PAD,CAD(Replication)
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37_GP73_6.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)

outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('ieu-a-798','ukb-d-I9_PAD','finn-b-I9_CHD'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
MR_Final_MI<-mr(dat, method_list=c("mr_ivw_fe","mr_ivw_mre","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))
MR_
MR_Final_MI$OR<-exp(MR_Final$b)
MR_Final_MI$L95<-exp(MR_Final$b-1.96*MR_Final$se)
MR_Final_MI$H95<-exp(MR_Final$b+1.96*MR_Final$se)

####AIS
setwd("D:/R_FILES/MEGASTROKE_data")
#AIS<-read.table("MEGASTROKE.2.AIS.EUR.out",header = TRUE)
setwd("D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata")
AGES<-read.csv("SNP_GRCH37_GP73_6.csv",header=TRUE)
SNP_list<-AGES$SNP
selected<-AIS[,1] %in% SNP_list
AIS2<-cbind(AIS,selected)
AIS_select<-subset(AIS2,selected=="TRUE")
setwd("D:/R_Files")
write.csv(AIS_select,"AIS_select.csv")

setwd("D:/R_Files")
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37_GP73_6.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome <- read_outcome_data(
  snps =exposure_dat$SNP,
  filename =  "AIS_select.csv",
  sep = ",",
  snp_col = "MarkerName",
  beta_col = "Effect",
  se_col = "StdErr",
  effect_allele_col = "Allele1",
  other_allele_col = "Allele2",
  eaf_col = "Freq1",
  pval_col = "P.value",
  units_col = "Units",
  gene_col = "Gene",
  phenotype = "outcome",
  samplesize_col = "N"
)
dat <- harmonise_data(
  exposure_dat = exposure_dat,
  outcome_dat =outcome
)	
AIS_res <- mr(dat, method_list=c("mr_ivw_mre","mr_ivw_fe","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))


#####LAS
setwd("D:/R_FILES/MEGASTROKE_data")
#LAS<-read.table("MEGASTROKE.3.LAS.EUR.out",header = TRUE)

setwd("D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata")
AGES<-read.csv("SNP_GRCH37_GP73_6.csv",header=TRUE)
SNP_list<-AGES$SNP
selected<-LAS[,1] %in% SNP_list
LAS2<-cbind(LAS,selected)
LAS_select<-subset(LAS2,selected=="TRUE")
setwd("D:/R_Files")
write.csv(LAS_select,"LAS_select.csv")

setwd("D:/R_Files")
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37_GP73_6.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome <- read_outcome_data(
  snps =exposure_dat$SNP,
  filename =  "LAS_select.csv",
  sep = ",",
  snp_col = "MarkerName",
  beta_col = "Effect",
  se_col = "StdErr",
  effect_allele_col = "Allele1",
  other_allele_col = "Allele2",
  eaf_col = "Freq1",
  pval_col = "P.value",
  units_col = "Units",
  gene_col = "Gene",
  phenotype = "outcome",
  samplesize_col = "N"
)
dat <- harmonise_data(
  exposure_dat = exposure_dat,
  outcome_dat =outcome
)	
LAS_res <- mr(dat, method_list=c("mr_ivw_mre","mr_ivw_fe","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))


#####SVS
setwd("D:/R_FILES/MEGASTROKE_data")
#SVS<-read.table("MEGASTROKE.5.SVS.EUR.out",header = TRUE)

setwd("D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata")
AGES<-read.csv("SNP_GRCH37_GP73_6.csv",header=TRUE)
SNP_list<-AGES$SNP
selected<-SVS[,1] %in% SNP_list
SVS2<-cbind(SVS,selected)
SVS_select<-subset(SVS2,selected=="TRUE")
setwd("D:/R_Files")
write.csv(SVS_select,"SVS_select.csv")


setwd("D:/R_Files")
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37_GP73_6.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome <- read_outcome_data(
  snps =exposure_dat$SNP,
  filename =  "SVS_select.csv",
  sep = ",",
  snp_col = "MarkerName",
  beta_col = "Effect",
  se_col = "StdErr",
  effect_allele_col = "Allele1",
  other_allele_col = "Allele2",
  eaf_col = "Freq1",
  pval_col = "P.value",
  units_col = "Units",
  gene_col = "Gene",
  phenotype = "outcome",
  samplesize_col = "N"
)
dat <- harmonise_data(
  exposure_dat = exposure_dat,
  outcome_dat =outcome
)	
SVS_res <- mr(dat, method_list=c("mr_ivw_mre","mr_ivw_fe","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))

#####Network MR
#####Independent variable to mediators
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('ieu-a-780','ieu-a-782','ieu-a-781','ieu-b-117','ieu-b-118','ieu-b-103'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
X_Mediator_result<-mr(dat, method_list=c("mr_ivw_mre","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))

#####Independent variable to mediators(REPLICATION for LDL-C and HbA1c)
library(TwoSampleMR)
pQTL_FILES <- "D:/Program Files/R/R-4.0.3/library/TwoSampleMR/extdata/SNP_GRCH37.csv"
exposure_dat <- read_exposure_data(
  filename = pQTL_FILES,
  sep = ',',
  snp_col = 'SNP',
  beta_col = 'beta',
  se_col = 'se',
  effect_allele_col = 'effect_allele',
  phenotype_col = 'Phenotype',
  other_allele_col = 'other_allele',
  eaf_col = 'eaf',
  samplesize_col = 'samplesize',
  pval_col = 'pval'
)
outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('bbj-a-31','ukb-d-30750_raw'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
X_Mediator_result<-mr(dat, method_list=c("mr_ivw_mre","mr_weighted_median","mr_weighted_mode","mr_egger_regression"))


#####Mediators to outcome
library(TwoSampleMR)
ao <- available_outcomes()
exposure_dat <- extract_instruments(c('ieu-a-7','ieu-b-103'))
outcome_dat <- extract_outcome_data(exposure_dat$SNP, c('ieu-a-7'), proxies = 1, rsq = 0.8, align_alleles = 1, palindromes = 1, maf_threshold = 0.3)
dat <- harmonise_data(exposure_dat, outcome_dat, action = 2)
mr_results <- mr(dat)

