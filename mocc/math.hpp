#pragma once

#include "mocc.hpp"
#include <cmath>

/* An object that calculates the "mean" and the "standard deviation" of a
 * dataset without storing the data points of the dataset. The "mean" and the
 * "standard deviation" are calculated online as the data points are inserted in
 * the object.
 *
 * OnlineDataAnalysis project_cost;
 * project_cost.insertDataPoint(10000);
 * project_cost.insertDataPoint(20000);
 *
 * project_cost.mean(); // 15000
 * project_cost.stddev(); // 5000
 * */
class DataDistribution {
  private:
    real_t mean_ = 0, m_2__ = 0;
    size_t number_of_data_points = 0;

  public:
    /* Updates the "mean" by using an incremental formula [sec. 1.3.1].
     * Updates the "standard deviation" by using Welford's algo. [sec. 1.3.2].
     * */
    void insertDataPoint(real_t);

    /* Returns the "mean" of the data points inserted. */
    real_t mean() const;

    /* Returns the "standard deviation" of the data points inserted. */
    real_t stddev() const;
};
