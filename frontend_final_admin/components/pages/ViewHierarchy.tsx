'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { TreePine, ChevronRight, ChevronDown, Users, Search, RefreshCw } from 'lucide-react';
import { getGroupHierarchy } from '@/lib/api';

interface Group {
  id: string;
  name: string;
  path: string;
  contactCount?: number;
  children?: Group[];
}

interface TreeNodeProps {
  group: Group;
  level: number;
  searchTerm: string;
}

const TreeNode = ({ group, level, searchTerm }: TreeNodeProps) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const hasChildren = group.children && group.children.length > 0;

  const matchesSearch = searchTerm === '' ||
    group.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    group.path.toLowerCase().includes(searchTerm.toLowerCase());

  const hasMatchingChildren = group.children?.some(child =>
    child.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    child.path.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (!matchesSearch && !hasMatchingChildren) {
    return null;
  }

  return (
    <div className="select-none">
      <div
        className={`flex items-center space-x-2 p-2 rounded-lg hover:bg-gray-50 cursor-pointer ${
          matchesSearch ? 'bg-blue-50' : ''
        }`}
        style={{ paddingLeft: `${level * 20 + 8}px` }}
        onClick={() => setIsExpanded(!isExpanded)}
      >
        {hasChildren ? (
          isExpanded ? (
            <ChevronDown className="h-4 w-4 text-gray-400" />
          ) : (
            <ChevronRight className="h-4 w-4 text-gray-400" />
          )
        ) : (
          <div className="w-4 h-4" />
        )}

        <TreePine className="h-4 w-4 text-green-600" />

        <span className={`font-medium ${matchesSearch ? 'text-blue-700' : 'text-gray-900'}`}>
          {group.name}
        </span>

        {group.contactCount !== undefined && (
          <div className="flex items-center space-x-1 text-sm text-gray-500">
            <Users className="h-3 w-3" />
            <span>{group.contactCount}</span>
          </div>
        )}
      </div>

      {isExpanded && hasChildren && (
        <div>
          {group.children!.map((child) => (
            <TreeNode key={child.id} group={child} level={level + 1} searchTerm={searchTerm} />
          ))}
        </div>
      )}
    </div>
  );
};

export default function ViewHierarchy() {
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [groupName, setGroupName] = useState('');

  const loadHierarchy = async (groupName?: string) => {
    setLoading(true);
    try {
      const data = await getGroupHierarchy(groupName);
      setGroups(data);
    } catch (error) {
      console.error('Failed to load hierarchy:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadHierarchy(); // load all on mount
  }, []);

  const getTotalGroups = (groups: Group[]): number => {
    return groups.reduce((total, group) => {
      return total + 1 + (group.children ? getTotalGroups(group.children) : 0);
    }, 0);
  };

  const getTotalContacts = (groups: Group[]): number => {
    return groups.reduce((total, group) => {
      const groupContacts = group.contactCount || 0;
      const childContacts = group.children ? getTotalContacts(group.children) : 0;
      return total + groupContacts;
    }, 0);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Group Hierarchy</h1>
          <p className="text-gray-600 mt-2">View the full hierarchy of groups and subgroups</p>
        </div>
        <Button onClick={() => loadHierarchy(groupName)} disabled={loading} variant="outline">
          <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <TreePine className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-sm text-gray-600">Total Groups</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : getTotalGroups(groups)}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <Users className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-sm text-gray-600">Total Contacts</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : getTotalContacts(groups)}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center space-x-2">
              <TreePine className="h-5 w-5 text-purple-600" />
              <div>
                <p className="text-sm text-gray-600">Root Groups</p>
                <p className="text-2xl font-bold text-gray-900">
                  {loading ? '...' : groups.length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search & Filter */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <TreePine className="h-5 w-5" />
            <span>Group Structure</span>
          </CardTitle>
          <div className="flex items-center gap-2">
            <Input
              placeholder="Filter by group name..."
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
              className="max-w-sm"
            />
            <Button onClick={() => loadHierarchy(groupName)}>Filter</Button>
            <Input
              placeholder="Search inside tree..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="max-w-sm"
            />
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center p-8">
              <RefreshCw className="h-6 w-6 animate-spin text-gray-400" />
              <span className="ml-2 text-gray-600">Loading hierarchy...</span>
            </div>
          ) : groups.length === 0 ? (
            <div className="text-center p-8 text-gray-500">
              <TreePine className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>No groups found. Upload group structure to get started.</p>
            </div>
          ) : (
            <div className="space-y-1 max-h-[60vh] overflow-y-auto">
              {groups.map((group) => (
                <TreeNode key={group.id} group={group} level={0} searchTerm={searchTerm} />
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
