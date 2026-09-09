# ============================================================
# PROJECT: U.S. Fatal Police Encounters Analysis (2013–2025)
# AUTHOR: Oluwatobiloba Adenola
# WEBSITE: https://tobiadenola.com
#
# PURPOSE:
# Explore long-term trends in fatal police encounters in the
# United States using Mapping Police Violence data.
# ============================================================


# 1. LOAD PACKAGES --------------------------------------------------------

library(tidyverse)
library(lubridate)
library(janitor)
library(zoo)


# 2. LOAD DATA ------------------------------------------------------------

# The dataset should be stored in the "data" folder.
police_killings <- read_csv(
  "data/police_killings.csv",
  show_col_types = FALSE
)


# 3. CLEAN DATA -----------------------------------------------------------

# Standardize column names and convert the incident date
# into a proper R date object.

police_killings_clean <- police_killings %>%
  clean_names() %>%
  mutate(
    incident_date = mdy(date_of_incident_month_day_year)
  ) %>%
  filter(!is.na(incident_date))


# 4. CREATE DEMOGRAPHIC GROUPS -------------------------------------------

# Group records into White, Black, Hispanic, and Other/Unknown.

police_killings_by_race <- police_killings_clean %>%
  mutate(
    race_group = case_when(
      victims_race == "White" ~ "White",
      victims_race == "Black" ~ "Black",
      victims_race == "Hispanic" ~ "Hispanic",
      TRUE ~ "Other/Unknown"
    )
  )


# 5. OVERALL MONTHLY TREND ------------------------------------------------

overall_trend <- police_killings_by_race %>%
  mutate(
    month_year = floor_date(incident_date, unit = "month")
  ) %>%
  count(month_year, name = "incidents") %>%
  arrange(month_year) %>%
  mutate(
    rolling_average = rollmean(
      incidents,
      k = 6,
      fill = NA,
      align = "right"
    )
  )


# 6. PLOT OVERALL TREND ---------------------------------------------------

national_pulse <- ggplot(
  overall_trend,
  aes(x = month_year)
) +
  geom_line(
    aes(y = incidents),
    alpha = 0.25,
    linewidth = 0.5
  ) +
  geom_line(
    aes(y = rolling_average),
    linewidth = 1.2
  ) +
  labs(
    title = "Monthly Trends in Fatal Police Encounters",
    subtitle = "2013–2025 with a 6-month rolling average",
    x = NULL,
    y = "Fatal encounters"
  ) +
  theme_minimal()

national_pulse


# Save figure
ggsave(
  filename = "figures/national_pulse.png",
  plot = national_pulse,
  width = 8,
  height = 5,
  dpi = 300
)


# 7. MONTHLY TRENDS BY DEMOGRAPHIC GROUP ---------------------------------

demographic_trends <- police_killings_by_race %>%
  filter(
    race_group %in% c("White", "Black", "Hispanic")
  ) %>%
  mutate(
    month_year = floor_date(incident_date, unit = "month")
  ) %>%
  count(month_year, race_group, name = "incidents") %>%
  group_by(race_group) %>%
  arrange(month_year, .by_group = TRUE) %>%
  mutate(
    rolling_average = rollmean(
      incidents,
      k = 6,
      fill = NA,
      align = "right"
    )
  ) %>%
  ungroup()


# 8. PLOT DEMOGRAPHIC TRENDS ---------------------------------------------

demographic_divergence <- ggplot(
  demographic_trends,
  aes(
    x = month_year,
    y = rolling_average,
    group = race_group
  )
) +
  geom_line(linewidth = 1) +
  facet_wrap(
    ~race_group,
    ncol = 1,
    scales = "free_y"
  ) +
  labs(
    title = "Fatal Police Encounters by Demographic Group",
    subtitle = "Six-month rolling averages for White, Black, and Hispanic individuals",
    x = "Year",
    y = "6-Month Rolling Average"
  ) +
  theme_minimal()

demographic_divergence


# Save figure
ggsave(
  filename = "figures/demographic_divergence.png",
  plot = demographic_divergence,
  width = 8,
  height = 10,
  dpi = 300
)


# 9. 2025 DEMOGRAPHIC SUMMARY --------------------------------------------

summary_2025 <- police_killings_by_race %>%
  filter(year(incident_date) == 2025) %>%
  count(race_group, name = "cases") %>%
  mutate(
    percentage = round(
      cases / sum(cases) * 100,
      1
    )
  ) %>%
  arrange(desc(percentage))


# Display the 2025 summary table
print(summary_2025)
