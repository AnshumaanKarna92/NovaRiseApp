export type UserRole = "admin" | "teacher" | "parent" | "cash_collector";

export interface RequestContext {
  uid: string;
  role: UserRole;
  schoolId: string;
}
