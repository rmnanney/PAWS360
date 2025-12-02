'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './Card/card'
import { Badge } from './Badge/badge'
import { Button } from './Others/button'
import { Input } from './Others/input'
import { Label } from './Others/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './Others/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './Others/table'
import { Tabs, TabsContent, TabsList, TabsTrigger } from './Others/tabs'
import { Alert, AlertDescription } from './Others/alert'
import { Loader2, Search, Users, CheckCircle, XCircle } from 'lucide-react'

interface AdminDashboardStats {
  student_counts: {
    total_students: number
    active_students: number
    students_with_gpa: number
    students_with_campus_id: number
  }
  active_sessions: number
  session_stats: Array<[string, number]>
  generated_at: string
}

interface StudentSummary {
  user_id: number
  student_id: number
  email: string
  firstname: string
  lastname: string
  preferred_name?: string
  campus_id: string
  department: string
  standing: string
  enrollment_status: string
  gpa: number
  status: string
  last_updated: string
  account_created: string
}

interface StudentSearchResponse {
  students: StudentSummary[]
  count: number
  total_available: number
  query?: string
  department?: string
  limit: number
}

interface DataConsistencyResult {
  valid: boolean
  user_id: number
  student_id: number
  has_campus_id: boolean
  has_department: boolean
  has_gpa: boolean
  enrollment_status: string
  account_status: string
  admin_verified: boolean
  validated_by: string
  validation_timestamp: string
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<AdminDashboardStats | null>(null)
  const [students, setStudents] = useState<StudentSummary[]>([])
  const [selectedStudent, setSelectedStudent] = useState<any>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedDepartment, setSelectedDepartment] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [validationResult, setValidationResult] = useState<DataConsistencyResult | null>(null)

  const API_BASE = 'http://localhost:8086'

  // Load initial dashboard stats
  useEffect(() => {
    loadDashboardStats()
    loadAllStudents()
  }, [])

  const loadDashboardStats = async () => {
    try {
      setLoading(true)
      const response = await fetch(`${API_BASE}/admin/dashboard/stats`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Failed to load stats: ${response.status}`)
      }

      const data = await response.json()
      setStats(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load dashboard stats')
    } finally {
      setLoading(false)
    }
  }

  const loadAllStudents = async () => {
    try {
      setLoading(true)
      const response = await fetch(`${API_BASE}/admin/students/search?limit=100`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Failed to load students: ${response.status}`)
      }

      const data: StudentSearchResponse = await response.json()
      setStudents(data.students)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load students')
    } finally {
      setLoading(false)
    }
  }

  const searchStudents = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (searchQuery.trim()) params.append('query', searchQuery)
      if (selectedDepartment) params.append('department', selectedDepartment)
      params.append('limit', '100')

      const response = await fetch(`${API_BASE}/admin/students/search?${params}`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Search failed: ${response.status}`)
      }

      const data: StudentSearchResponse = await response.json()
      setStudents(data.students)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Search failed')
    } finally {
      setLoading(false)
    }
  }

  const loadStudentDetails = async (userId: number) => {
    try {
      setLoading(true)
      const response = await fetch(`${API_BASE}/admin/students/${userId}`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Failed to load student details: ${response.status}`)
      }

      const data = await response.json()
      setSelectedStudent(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load student details')
    } finally {
      setLoading(false)
    }
  }

  const validateStudentData = async (userId: number) => {
    try {
      setLoading(true)
      const response = await fetch(`${API_BASE}/admin/students/${userId}/validate`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        },
      })

      if (!response.ok) {
        throw new Error(`Validation failed: ${response.status}`)
      }

      const data: DataConsistencyResult = await response.json()
      setValidationResult(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Data validation failed')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString()
  }

  const getStatusBadge = (status: string) => {
    const variant = status === 'ACTIVE' ? 'default' : 'secondary'
    return <Badge variant={variant}>{status}</Badge>
  }

  const getEnrollmentBadge = (status: string) => {
    const variants: { [key: string]: 'default' | 'secondary' | 'destructive' | 'outline' } = {
      'ENROLLED': 'default',
      'GRADUATED': 'secondary',
      'WITHDRAWN': 'destructive',
      'SUSPENDED': 'outline'
    }
    return <Badge variant={variants[status] || 'outline'}>{status}</Badge>
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Admin Dashboard</h1>
        <Button onClick={loadDashboardStats} disabled={loading}>
          {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
          Refresh
        </Button>
      </div>

      {error && (
        <Alert>
          <XCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="students">Student Search</TabsTrigger>
          <TabsTrigger value="validation">Data Validation</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {stats && (
              <>
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Students</CardTitle>
                    <Users className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.student_counts.total_students}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Active Students</CardTitle>
                    <CheckCircle className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.student_counts.active_students}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Students with GPA</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.student_counts.students_with_gpa}</div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Active Sessions</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{stats.active_sessions}</div>
                  </CardContent>
                </Card>
              </>
            )}
          </div>

          {stats && (
            <Card>
              <CardHeader>
                <CardTitle>Session Statistics</CardTitle>
                <CardDescription>Active sessions by service</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {stats.session_stats.map(([service, count], index) => (
                    <div key={index} className="flex justify-between items-center">
                      <span className="text-sm font-medium">{service}</span>
                      <Badge variant="outline">{count}</Badge>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="students" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Student Search</CardTitle>
              <CardDescription>Search and manage student records</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1">
                  <Label htmlFor="search">Search Students</Label>
                  <Input
                    id="search"
                    placeholder="Name, email, or campus ID..."
                    value={searchQuery}
                    onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchQuery(e.target.value)}
                    onKeyPress={(e: React.KeyboardEvent<HTMLInputElement>) => e.key === 'Enter' && searchStudents()}
                  />
                </div>
                <div className="md:w-48">
                  <Label htmlFor="department">Department</Label>
                  <Select value={selectedDepartment} onValueChange={setSelectedDepartment}>
                    <SelectTrigger>
                      <SelectValue placeholder="All Departments" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="">All Departments</SelectItem>
                      <SelectItem value="Computer Science">Computer Science</SelectItem>
                      <SelectItem value="Engineering">Engineering</SelectItem>
                      <SelectItem value="Business">Business</SelectItem>
                      <SelectItem value="Mathematics">Mathematics</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex items-end">
                  <Button onClick={searchStudents} disabled={loading}>
                    <Search className="mr-2 h-4 w-4" />
                    Search
                  </Button>
                </div>
              </div>

              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Campus ID</TableHead>
                      <TableHead>Department</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>GPA</TableHead>
                      <TableHead>Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {students.map((student) => (
                      <TableRow key={student.user_id}>
                        <TableCell>
                          <div>
                            <div className="font-medium">
                              {student.preferred_name || `${student.firstname} ${student.lastname}`}
                            </div>
                            {student.preferred_name && (
                              <div className="text-sm text-muted-foreground">
                                {student.firstname} {student.lastname}
                              </div>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>{student.email}</TableCell>
                        <TableCell>{student.campus_id}</TableCell>
                        <TableCell>{student.department}</TableCell>
                        <TableCell>{getStatusBadge(student.status)}</TableCell>
                        <TableCell>{student.gpa ? student.gpa.toFixed(2) : 'N/A'}</TableCell>
                        <TableCell>
                          <div className="flex gap-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => loadStudentDetails(student.user_id)}
                            >
                              View
                            </Button>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => validateStudentData(student.user_id)}
                            >
                              Validate
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>

          {selectedStudent && (
            <Card>
              <CardHeader>
                <CardTitle>Student Details</CardTitle>
                <CardDescription>Complete student profile information</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h3 className="text-lg font-semibold mb-3">User Information</h3>
                    <div className="space-y-2">
                      <div><strong>User ID:</strong> {selectedStudent.user.user_id}</div>
                      <div><strong>Name:</strong> {selectedStudent.user.firstname} {selectedStudent.user.lastname}</div>
                      <div><strong>Preferred Name:</strong> {selectedStudent.user.preferred_name || 'N/A'}</div>
                      <div><strong>Email:</strong> {selectedStudent.user.email}</div>
                      <div><strong>Phone:</strong> {selectedStudent.user.phone || 'N/A'}</div>
                      <div><strong>Status:</strong> {getStatusBadge(selectedStudent.user.status)}</div>
                      <div><strong>Role:</strong> {selectedStudent.user.role}</div>
                      <div><strong>Created:</strong> {formatDate(selectedStudent.user.created_at)}</div>
                    </div>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold mb-3">Academic Information</h3>
                    <div className="space-y-2">
                      <div><strong>Student ID:</strong> {selectedStudent.student.student_id}</div>
                      <div><strong>Campus ID:</strong> {selectedStudent.student.campus_id}</div>
                      <div><strong>Department:</strong> {selectedStudent.student.department}</div>
                      <div><strong>Standing:</strong> {selectedStudent.student.standing}</div>
                      <div><strong>Enrollment:</strong> {getEnrollmentBadge(selectedStudent.student.enrollment_status)}</div>
                      <div><strong>GPA:</strong> {selectedStudent.student.gpa ? selectedStudent.student.gpa.toFixed(2) : 'N/A'}</div>
                      <div><strong>Expected Graduation:</strong> {selectedStudent.student.expected_graduation || 'N/A'}</div>
                      <div><strong>Last Updated:</strong> {formatDate(selectedStudent.student.updated_at)}</div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="validation" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Data Consistency Validation</CardTitle>
              <CardDescription>Validate data consistency between student portal and admin views</CardDescription>
            </CardHeader>
            <CardContent>
              {validationResult && (
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    {validationResult.valid ? (
                      <CheckCircle className="h-5 w-5 text-green-500" />
                    ) : (
                      <XCircle className="h-5 w-5 text-red-500" />
                    )}
                    <span className="font-medium">
                      Data Validation {validationResult.valid ? 'Passed' : 'Failed'}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h4 className="font-semibold mb-2">Validation Details</h4>
                      <div className="space-y-1 text-sm">
                        <div>User ID: {validationResult.user_id}</div>
                        <div>Student ID: {validationResult.student_id}</div>
                        <div>Has Campus ID: {validationResult.has_campus_id ? '✓' : '✗'}</div>
                        <div>Has Department: {validationResult.has_department ? '✓' : '✗'}</div>
                        <div>Has GPA: {validationResult.has_gpa ? '✓' : '✗'}</div>
                        <div>Enrollment Status: {validationResult.enrollment_status}</div>
                        <div>Account Status: {validationResult.account_status}</div>
                      </div>
                    </div>
                    <div>
                      <h4 className="font-semibold mb-2">Validation Metadata</h4>
                      <div className="space-y-1 text-sm">
                        <div>Admin Verified: {validationResult.admin_verified ? '✓' : '✗'}</div>
                        <div>Validated By: {validationResult.validated_by}</div>
                        <div>Timestamp: {new Date(validationResult.validation_timestamp).toLocaleString()}</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}