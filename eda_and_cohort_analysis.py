"""
E-Commerce Customer & Sales Analytics Pipeline
Performs date-time transformations, AOV distribution, and cohort retention analysis.
"""

import pandas as pd
import numpy as np

def compute_monthly_metrics(df):
    """
    Transforms order timestamps, computes monthly revenue and Average Order Value (AOV).
    """
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['order_month'] = df['order_date'].dt.to_period('M')

    monthly_summary = df.groupby('order_month').agg(
        total_revenue=('total_amount', 'sum'),
        total_orders=('order_id', 'nunique'),
        unique_customers=('customer_id', 'nunique')
    ).reset_index()

    monthly_summary['average_order_value'] = (
        monthly_summary['total_revenue'] / monthly_summary['total_orders']
    ).round(2)

    return monthly_summary

def cohort_retention_matrix(df):
    """
    Computes month-on-month customer retention percentages.
    """
    df['order_date'] = pd.to_datetime(df['order_date'])
    df['order_month'] = df['order_date'].dt.to_period('M')
    df['cohort_month'] = df.groupby('customer_id')['order_date'].transform('min').dt.to_period('M')

    # Calculate period index
    year_diff = df['order_month'].dt.year - df['cohort_month'].dt.year
    month_diff = df['order_month'].dt.month - df['cohort_month'].dt.month
    df['cohort_index'] = year_diff * 12 + month_diff + 1

    cohort_data = df.groupby(['cohort_month', 'cohort_index'])['customer_id'].nunique().reset_index()
    cohort_matrix = cohort_data.pivot(index='cohort_month', columns='cohort_index', values='customer_id')

    cohort_sizes = cohort_matrix.iloc[:, 0]
    retention_matrix = cohort_matrix.divide(cohort_sizes, axis=0).round(3) * 100

    return retention_matrix

if __name__ == "__main__":
    print("E-commerce analytics and cohort pipeline module ready.")
