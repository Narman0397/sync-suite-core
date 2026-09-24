// Hook konsumsi permission dari AuthProvider.
import { useAuthRoles } from "@/lib/auth-context";
import type { Permission } from "./constants";

export function usePermissions(): Set<string> {
  return useAuthRoles().permissions ?? new Set<string>();
}

export function useCan(permission: Permission | Permission[]): boolean {
  const { isSuperAdmin, permissions } = useAuthRoles();
  if (isSuperAdmin) return true;
  const list = Array.isArray(permission) ? permission : [permission];
  return list.some((p) => permissions.has(p));
}

export function useCanAll(permissions: Permission[]): boolean {
  const { isSuperAdmin, permissions: perms } = useAuthRoles();
  if (isSuperAdmin) return true;
  return permissions.every((p) => perms.has(p));
}
