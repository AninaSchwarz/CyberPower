# This script normalizes the cyber power variables and produces an aggregated cyber power measure using the package "compind"
###(data=May 12)

rm(list=ls())

# FOR NOW: CHECKED ONLY OVERALL SCORES

# -------------- OBJECTIVES X CAPABILITIES MAP

# Commercial = Commercial Gain of Enhancing Domestic Industry Growth
# Defense = Strengthening and Enhancing National Cyber Defenses
# Intelligence = Foreign Intelligence Collection for National Security
# Information Control = Controlling and Manipulating the Information Environment
# Norms = Defining International Cyber Norms and Standards
# Offense = Destroying or Disabling Adversary Infrastructure
# Surveillance = Surveilling and Monitoring Domestic Groups

# --- 0. Setup
# install.packages("GGally")

library(tidyverse)
library(foreign) 
library(dplyr)
library(Compind)
library(xtable)
library(ggplot2)
library(GGally)
library(Hmisc)
library(ggcorrplot)

# -------------- FUNCTION

crimson_theme <- function() {
  # font <- "Georgia"   #assign font family up front
  theme_minimal() %+replace%    #replace elements we want to change
    theme(
      # add border 1)
      panel.border = element_rect(colour = "blue", fill = NA, linetype = 2),
      # color background 2)
      panel.background = element_rect(fill = "aliceblue"),
      # modify grid 3)
      panel.grid.major.x = element_line(colour = "#A51C30", linetype = 3, size = 0.5),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y =  element_line(colour = "#A51C30", linetype = 3, size = 0.5),
      panel.grid.minor.y = element_blank(),
      axis.title = element_text(size = 15),
      # modify text, axis and colour 4) and 5)
      # axis.text = element_text(colour = "black", face = "italic", family = "Times New Roman"),
      # axis.title = element_text(colour = "black", family = "Times New Roman"),
      axis.ticks = element_line(colour = "black"),
      # legend at the bottom 6)
      legend.position = "bottom"
    )
}


# -------------- DATA IMPORT

CPI <- readRDS("../../data/data_for_modelling/CPI_2020.rds") 
  # filter(country != "North Korea") # remove North Korea for now because of missing information

CPI_countries <- readRDS("../../data/data_for_modelling/CPI_countries.rds") 
  # filter(country != "North Korea") # remove North Korea for now because of missing information

overall <- readRDS("../../data/data_for_modelling/CPI_2020.rds") %>%
  select(country, web_alexa, news_alexa, removal_google, freedom_net, 
         patent_app_capita, broadband_speed, mobile_speed,ecommerce_capita,
         tech_firm, tech_export, human_capital, cybermil_people,cyber_firm, computer_infection,
         mobile_infection, socials_use, internet_use, surveillance_firm, shodan, military_strategy, cyber_command, CERTS, multi_agreement, bilat_agreement, softpower)


# -------------- SUBSET DATA

surveillance <- CPI %>%
  select(country,laws, attack_surveillance, freedom_net, surveillance_firm, socials_use, internet_use)
defense <- CPI %>%
  select(country, laws, shodan,  human_capital, cyber_firm, computer_infection, mobile_infection, internet_use, broadband_speed, mobile_speed, infocomm_imp, CERTS)
control <- CPI %>%
  select(country, attack_control, internet_use, socials_use, news_alexa, web_alexa, removal_google)
intelligence <- CPI %>%
  select(country, attack_intelligence, tech_export, human_capital, cybermil_people, tech_firm, surveillance_firm)
commercial <- CPI %>%
  select(country, attack_commercial, tech_firm, human_capital, cyber_firm, web_alexa, ecommerce_capita, tech_export, infocomm_imp, patent_app_capita)
offense <- CPI %>%
  select(country, attack_offense, tech_export, cybermil_people, military_strategy, cyber_command)
norms <- CPI %>%
  select(country, laws, muli_agreement, bilat_agreement, infocomm_imp, tech_firm, tech_export, softpower)

# -------------- NORMALIZATION (Z-SCORE)
# https://www.researchgate.net/post/What_are_the_best_normalization_methods_Z-Score_Min-Max_etc_How_would_you_choose_a_data_normalization_method

# Normalization methods
# # 1 (default) = standardization or z-scores. The formula for calculating a z-score is is z = (x-μ)/σ, where x is the raw score, μ is the population mean, and σ is the population standard deviation
# # 2 = Min-max method
# # 3 = Ranking method. If polarity="POS" ranking is increasing, while if polarity="NEG" ranking is decreasing

colnames(CPI) # show column names CPI


### ### ### ### ### ### 

### --- RUN THIS SECTION

# CPI_overall


# Z-score

data_norm = normalise_ci(overall,c(2:26),c("POS","POS", "POS",
                                           "POS","POS","POS","POS","POS","POS","POS","POS","POS", "POS",
                                           "NEG","NEG","POS","POS","POS","NEG","POS","POS","POS", "POS","POS","POS"),
                            method=1,z.mean=50, z.std=20)

CPI_norm <- cbind(CPI_countries$country, data_norm$ci_norm)  %>% # Create a matrix where x, y and z are columns
  rename(country= `CPI_countries$country`)

CPI_z <- CPI_norm %>%
  gather(key, val, web_alexa:softpower)%>%
  group_by(country) %>%
  mutate(
    sum_norm = sum(val,  na.rm = TRUE),
    mean_overall = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val)

# Min-Max

data_norm = normalise_ci(overall,c(2:26),c("POS","POS", "POS",
                                           "POS","POS","POS","POS","POS","POS","POS","POS","POS", "POS",
                                           "NEG","NEG","POS","POS","POS","NEG","POS","POS","POS", "POS","POS","POS"),
                         method=2)

CPI_norm <- cbind(CPI_countries$country, data_norm$ci_norm)  %>% # Create a matrix where x, y and z are columns
  rename(country= `CPI_countries$country`)

CPI_minmax <- CPI_norm %>%
  gather(key, val, web_alexa:softpower)%>%
  group_by(country) %>%
  mutate(
    sum_norm = sum(val,  na.rm = TRUE),
    mean_overall = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val)

# Save as dataset

CPI_scores = data.frame(CPI, score_z = round(CPI_z$mean_overall),
                            score_minmax = round(CPI_minmax$mean_overall*100,3))


# Plot Z-score

capabilities_z <- CPI_scores %>% ungroup(country) %>%
  select(country, score_z) %>% mutate(country = fct_reorder(country, score_z)) %>% arrange(-score_z)

p_capabilities_z <- ggplot(data = capabilities_z, aes(x = country, y = score_z)) +
  geom_point(size =3, color = "#A51C30") +
  geom_segment(aes(xend = country, y = 0, yend = score_z)) +
  xlab("") +
  ylab("Capability Score") +
  ggtitle(" ") +
  coord_flip() +
  crimson_theme() +
  theme_minimal() + 
  scale_y_continuous(breaks = seq(0, 100, by = 10), limits = c(0,103), expand = c(0,0)) +
  theme(
    # plot.title = element_text(size = 20, face = "bold"),
    axis.text.x = element_text(colour="black", size = 12),
    axis.title.x=element_text(colour="black", size = 15), #, face = "bold") ,
    axis.text.y=element_text(colour="black", size = 15)
  ) 

ggsave(p_capabilities_z, file = "../../findings/CapabilitiesZScores_Index.pdf" , width = 15, height = 12)

# Plot Min Max

capabilities_minmax <- CPI_scores %>% ungroup(country) %>%
  select(country, score_minmax) %>% mutate(country = fct_reorder(country, score_minmax)) %>% arrange(-score_minmax)

p_capabilities_minmax <- ggplot(data = capabilities_minmax, aes(x = country, y = score_minmax)) +
  geom_point(size =3, color = "#A51C30") +
  geom_segment(aes(xend = country, y = 0, yend = score_minmax)) +
  xlab("") +
  ylab("Capability Score") +
  ggtitle(" ") +
  coord_flip() +
  crimson_theme() +
  theme_minimal() + 
  scale_y_continuous(breaks = seq(0, 100, by = 10), limits = c(0,103), expand = c(0,0)) +
  theme(
    # plot.title = element_text(size = 20, face = "bold"),
    axis.text.x = element_text(colour="black", size = 12),
    axis.title.x=element_text(colour="black", size = 15), #, face = "bold") ,
    axis.text.y=element_text(colour="black", size = 15)
  ) 

ggsave(p_capabilities_minmax, file = "../../findings/CapabilitiesMinMax_Index.pdf" , width = 15, height = 12)



### ### ### ### ### ### 


# CPI_surveillance
data_norm1 = normalise_ci(surveillance,c(2:7),c("POS","POS","POS","POS","POS","POS"),
                         method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm1 <- cbind(CPI_countries$country, data_norm1$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_surveillance <- CPI_norm1 %>% 
  gather(key, val, laws:internet_use)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_surveillance= mean_norm)

# CPI_defense
data_norm2 = normalise_ci(defense,c(2:12),c("POS","NEG","POS","POS","NEG","NEG","NEG","POS","POS","NEG", "POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm2 <- cbind(CPI_countries$country, data_norm2$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_defense <- CPI_norm2 %>% 
  gather(key, val, laws:CERTS)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_defense= mean_norm)

# CPI_control
data_norm3 = normalise_ci(control,c(2:7),c("POS","POS","POS","POS","POS","POS","POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm3 <- cbind(CPI_countries$country, data_norm3$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_control <- CPI_norm3 %>% 
  gather(key, val, attack_control:removal_google)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_control= mean_norm)

# CPI_intelligence
data_norm4 = normalise_ci(intelligence,c(2:7),c("POS","POS","POS","POS","POS","POS","POS","POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm4 <- cbind(CPI_countries$country, data_norm4$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_intelligence <- CPI_norm4 %>% 
  gather(key, val, attack_intelligence:surveillance_firm)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_intelligence= mean_norm)

# CPI_commercial
data_norm5 = normalise_ci(commercial,c(2:10),c("POS","POS","POS","POS","POS","POS","POS","NEG", "POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm5 <- cbind(CPI_countries$country, data_norm5$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_commercial <- CPI_norm5 %>% 
  gather(key, val, attack_commercial:patent_app_capita)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_commercial= mean_norm)

# CPI_offense
data_norm6 = normalise_ci(offense,c(2:6),c("POS","POS","POS", "POS", "POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm6 <- cbind(CPI_countries$country, data_norm6$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_offense <- CPI_norm6 %>% 
  gather(key, val, attack_offense:cyber_command)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_offense= mean_norm)

# CPI_norms
data_norm7 = normalise_ci(norms,c(2:8),c("POS","POS","POS","NEG", "POS", "POS", "POS"),
                          method=1,z.mean=50, z.std=20) #   method=1,z.mean=50, z.std=10)

CPI_norm7 <- cbind(CPI_countries$country, data_norm7$ci_norm)  %>% # Create a matrix where x, y and z are columns 
  rename(country= `CPI_countries$country`)

CPI_norms <- CPI_norm7 %>% 
  gather(key, val, laws:softpower)%>%
  group_by(country) %>%
  mutate(
    mean_norm = mean(val,  na.rm = TRUE)
  ) %>%
  spread(key, val) %>%
  select(country, mean_norms = mean_norm)


# -------------- COMBINED DATASET

CPI_scores_cap = data.frame(CPI, score_z = round(CPI_z$mean_overall),
                        score_surveillance = CPI_surveillance$mean_surveillance,
                        score_defense = CPI_defense$mean_defense, score_control = CPI_control$mean_control,
                        score_intelligence = CPI_intelligence$mean_intelligence, score_commercial = CPI_commercial$mean_commercial,
                        score_offense = CPI_offense$mean_offense, score_norms = CPI_norms$mean_norms
                        )


# 
# CPI_scores_cap <- CPI_scores_cap %>%
#   group_by(country) %>%
#   mutate(score_capabilities = mean(c(score_surveillance, score_defense, score_control, score_intelligence,
#                                   score_commercial, score_offense, score_norms), na.rm = TRUE ))
# 
# CPI_scores <- CPI_scores_cap %>%
#   group_by(country) %>%
#   mutate(capint_surveillance = (score_surveillance*intent_surveillance),
#          capint_defense = (score_defense*intent_defense),
#          capint_control = (score_control*intent_control),
#          capint_intelligence = (score_intelligence*intent_intelligence),
#          capint_commercial = (score_commercial*intent_commercial),
#          capint_offense = (score_offense*intent_offense),
#          capint_norms = (score_norms*intent_norms)
#          ) %>%
#   mutate(score_capint = mean(c(capint_surveillance, capint_defense, capint_control, 
#                                   capint_intelligence, capint_commercial, capint_offense, capint_norms), na.rm = TRUE)) %>%
#   ungroup(country)
# 

# -------------- 



# -------------- SAVE AND EXPORT DATASET
# 
# saveRDS(CPI_scores, file = "../../data/data_for_modelling/CPI_scores_z.rds")
# 
# rio:: export (CPI_scores, file = "../../data/data_for_modelling/CPI_scores_z.csv")



